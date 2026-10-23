import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/lighting/infrastructure/html_effects/effect_worker_connection.dart';
import 'package:lumivent/features/lighting/infrastructure/html_effects/effect_worker_protocol.dart';
import 'package:lumivent/features/lighting/infrastructure/html_effects/quickjs_effect.dart';
import 'package:lumivent/features/lighting/infrastructure/html_effects/effect_script_exception.dart';

part 'fake_stopwatch.dart';

/// `flutter test` only has the native QuickJS library when the Linux bundle was
/// built and `LD_LIBRARY_PATH` points at it (same requirement as the runtime
/// tests).
String? _quickJsSkip() {
  const names = [
    'libquickjs_c_bridge_plugin.so',
    'libquickjs_c_bridge_plugin.dylib',
    'quickjs_c_bridge_plugin.dll',
  ];
  for (final name in names) {
    try {
      DynamicLibrary.open(name).close();
      return null;
    } on Object {
      // Try the next platform name.
    }
  }
  return 'QuickJS native library unavailable: build the Linux bundle and set '
      'LD_LIBRARY_PATH=build/linux/x64/debug/bundle/lib.';
}

final _skip = Platform.isLinux || Platform.isMacOS || Platform.isWindows
    ? _quickJsSkip()
    : 'QuickJS tests only run on desktop.';

String effect({required String script}) =>
    '''
<!doctype html>
<html>
<head>
  <title>Test Effect</title>
</head>
<body><canvas id="exCanvas" width="320" height="200"></canvas></body>
<script>$script</script>
</html>
''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'a stuck frame script rejects its request, never silently returns',
    () async {
      final connection = await EffectWorkerConnection.spawn();
      addTearDown(connection.close);
      await connection.request(
        loadRequest(
          effect(
            script: '''
var ctx = document.getElementById('exCanvas').getContext('2d');
requestAnimationFrame(function () { while (true) {} });
''',
          ),
          await loadShim(),
          const {},
        ),
        timeout: scriptLoadLimit,
      );

      // The frame never returns: QuickJS interrupts the rAF callback and the
      // interrupt reply reaches the caller as a script error. The parent's own
      // hard timeout ('effect hung: … ms') covers the case where the interrupt
      // itself never answers.
      await expectLater(
        connection.request(frameRequest(0), timeout: scriptHardLimit),
        throwsA(
          isA<EffectScriptException>().having(
            (e) => e.message,
            'message',
            predicate<String>(
              (m) => m.contains('interrupted') || m.contains('effect hung'),
            ),
          ),
        ),
      );
    },
    skip: _skip,
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test(
    'a failed reload leaves no effect instead of the disposed one',
    () async {
      final connection = await EffectWorkerConnection.spawn();
      addTearDown(connection.close);
      final shim = await loadShim();
      await connection.request(
        loadRequest(
          effect(
            script: '''
var ctx = document.getElementById('exCanvas').getContext('2d');
requestAnimationFrame(function draw() {
  ctx.fillStyle = "red";
  ctx.fillRect(0, 0, 320, 200);
  requestAnimationFrame(draw);
});
''',
          ),
          shim,
          const {},
        ),
        timeout: scriptLoadLimit,
      );
      await expectLater(
        connection.request(
          loadRequest(
            effect(script: 'this is not javascript at all'),
            shim,
            {},
          ),
          timeout: scriptLoadLimit,
        ),
        throwsA(isA<EffectScriptException>()),
      );

      await expectLater(
        connection.request(frameRequest(0), timeout: scriptHardLimit),
        throwsA(
          isA<EffectScriptException>().having(
            (e) => e.message,
            'message',
            contains('no effect'),
          ),
        ),
      );
    },
    skip: _skip,
  );

  test('a load error arrives as a script exception, not a crash', () async {
    final connection = await EffectWorkerConnection.spawn();
    addTearDown(connection.close);
    // An unparsable script fails the load request with the script error.
    await expectLater(
      connection.request(
        loadRequest(
          effect(script: 'this is not javascript at all'),
          await loadShim(),
          const {},
        ),
        timeout: scriptLoadLimit,
      ),
      throwsA(isA<EffectScriptException>()),
    );
    // The worker itself is still alive (a valid effect loads after the
    // failure in a new QuickJS runtime).
    await expectLater(
      connection.request(
        loadRequest(
          effect(
            script: '''
var ctx = document.getElementById('exCanvas').getContext('2d');
ctx.fillStyle = "red";
''',
          ),
          await loadShim(),
          const {},
        ),
        timeout: scriptLoadLimit,
      ),
      completes,
    );
  }, skip: _skip);

  test('the process transport sends messages issued back to back', () async {
    final stdin = StreamController<List<int>>();
    final lines = <String>[];
    stdin.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(lines.add);
    final connection = EffectWorkerConnection.withStdin(IOSink(stdin));
    addTearDown(connection.close);

    // A runner tick sends the sample points and the frame in the same
    // synchronous run.
    connection.send(pointsRequest(null));
    final frame = connection.request(
      frameRequest(0),
      timeout: const Duration(seconds: 5),
    );
    connection.handleMessage([1, true, 'done']);

    expect(await frame, 'done');
    await pumpEventQueue();
    expect(lines.map(jsonDecode), [
      [0, ...pointsRequest(null)],
      [1, ...frameRequest(0)],
    ]);
  });

  group('request timeout', () {
    const timeout = Duration(milliseconds: 750);
    const stall = Duration(seconds: 2);

    late ReceivePort port;
    late _FakeStopwatch stopwatch;
    late EffectWorkerConnection connection;

    setUp(() {
      port = ReceivePort();
      stopwatch = _FakeStopwatch();
      connection = EffectWorkerConnection.withPort(
        port.sendPort,
        stopwatch: () => stopwatch,
      );
    });

    tearDown(() {
      connection.close();
      port.close();
    });

    Future<Object?> outcome(Future<Object?> request) =>
        request.then<Object?>((v) => v, onError: (Object e) => e);

    final hungError = isA<EffectScriptException>().having(
      (e) => e.message,
      'message',
      contains('effect hung'),
    );

    testWidgets('an on-time timeout fails immediately as hung', (tester) async {
      final result = outcome(connection.request(['frame'], timeout: timeout));
      stopwatch.elapsed = timeout;
      await tester.pump(timeout);

      expect(await result, hungError);
    });

    testWidgets('a stalled timer waits for a reply that is already queued', (
      tester,
    ) async {
      final result = outcome(connection.request(['frame'], timeout: timeout));
      // The main isolate was blocked: the timer fires 2 s late.
      stopwatch.elapsed = timeout + stall;
      await tester.pump(timeout);
      // The queued reply is delivered right after the stalled timer.
      connection.handleMessage([1, true, 'pong']);
      await tester.pump(const Duration(seconds: 1));

      expect(await result, 'pong');
    });

    testWidgets('a stalled timer still fails once the grace period passes', (
      tester,
    ) async {
      final result = outcome(connection.request(['frame'], timeout: timeout));
      stopwatch.elapsed = timeout + stall;
      await tester.pump(timeout);
      await tester.pump(const Duration(seconds: 1));

      expect(await result, hungError);
    });
  });
}
