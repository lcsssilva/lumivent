import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/lighting/infrastructure/html_effects/effect_worker_connection.dart';
import 'package:lumivent/features/lighting/infrastructure/html_effects/effect_worker_protocol.dart';
import 'package:lumivent/features/lighting/infrastructure/html_effects/quickjs_effect.dart';

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
}
