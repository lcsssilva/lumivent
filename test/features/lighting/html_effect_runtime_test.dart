import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/lighting/infrastructure/html_effects/runtime.dart';

/// `flutter test` only has the native QuickJS library when the Linux bundle was
/// built and `LD_LIBRARY_PATH` points at it.
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

String effect({required String script, String extraMeta = ''}) =>
    '''
<!doctype html>
<html>
<head>
  <title>Test Effect</title>
  <meta publisher="Teste" />
  <meta property="speed" label="Speed" type="number" min="0" max="100" default="10" />
  $extraMeta
</head>
<body><canvas id="exCanvas" width="320" height="200"></canvas></body>
<script>$script</script>
</html>
''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('binary canvas, properties, sensors, and audio silence', () async {
    final rt = await IsolatedHtmlEffectRuntime.load(
      effect(
        script: '''
var ctx = document.getElementById('exCanvas').getContext('2d');
function loop() {
  var sensor = engine.getSensorValue('cpu.tctl').value;
  var audio = engine.audio.level;
  if (speed > 50) ctx.fillStyle = '#0000ff';
  else if (sensor > 50) ctx.fillStyle = '#00ff00';
  else if (audio > -40) ctx.fillStyle = '#ffffff';
  else ctx.fillStyle = '#ff0000';
  ctx.fillRect(0, 0, 320, 200);
  requestAnimationFrame(loop);
}
loop();
''',
      ),
    );
    addTearDown(rt.dispose);
    expect(rt.effect.title, 'Test Effect');
    expect(rt.effect.properties.single.initialValue, 10);

    final first = await rt.renderFrame(0);
    expect(first.pixelAt(10, 10), (255, 0, 0));
    // The fill is a single rect: no JSON overhead and no path commands.
    expect(rt.lastOpCount, lessThanOrEqualTo(3));

    rt.setSensors({'cpu.tctl': 55});
    final second = await rt.renderFrame(16);
    expect(second.pixelAt(10, 10), (0, 255, 0));

    rt.setProperty('speed', 80);
    final third = await rt.renderFrame(32);
    expect(third.pixelAt(10, 10), (0, 0, 255));
    expect(rt.unknownOps, isEmpty);
  }, skip: _skip);

  test('beginPath + rect + fill becomes fillRect and gradients work', () async {
    final path = await IsolatedHtmlEffectRuntime.load(
      effect(
        script: '''
var ctx = document.getElementById('exCanvas').getContext('2d');
ctx.fillStyle = '#102030';
ctx.beginPath();
ctx.rect(0, 0, 320, 200);
ctx.fill();
''',
      ),
    );
    addTearDown(path.dispose);
    final f = await path.renderFrame(0);
    expect(f.pixelAt(160, 100), (0x10, 0x20, 0x30));
    expect(path.lastOpCount, lessThanOrEqualTo(4));

    final gradient = await IsolatedHtmlEffectRuntime.load(
      effect(
        script: '''
var ctx = document.getElementById('exCanvas').getContext('2d');
var g = ctx.createLinearGradient(0, 0, 320, 0);
g.addColorStop(0, '#ff0000');
g.addColorStop(1, '#0000ff');
ctx.fillStyle = g;
ctx.fillRect(0, 0, 320, 200);
''',
      ),
    );
    addTearDown(gradient.dispose);
    final g = await gradient.renderFrame(0);
    final (r0, _, b0) = g.pixelAt(2, 100);
    final (r1, _, b1) = g.pixelAt(317, 100);
    expect(r0, greaterThan(200));
    expect(b0, lessThan(60));
    expect(r1, lessThan(60));
    expect(b1, greaterThan(200));
  }, skip: _skip);

  test('hsl, rgb, hex and named colors', () async {
    final rt = await IsolatedHtmlEffectRuntime.load(
      effect(
        script: '''
var ctx = document.getElementById('exCanvas').getContext('2d');
ctx.fillStyle = 'hsl(120, 100%, 50%)';
ctx.fillRect(0, 0, 20, 20);
ctx.fillStyle = 'rgb(0, 0, 255)';
ctx.fillRect(20, 0, 20, 20);
ctx.fillStyle = 'red';
ctx.fillRect(40, 0, 20, 20);
ctx.fillStyle = '#00ffff';
ctx.fillRect(60, 0, 20, 20);
''',
      ),
    );
    addTearDown(rt.dispose);
    final f = await rt.renderFrame(0);
    expect(f.pixelAt(10, 10), (0, 255, 0));
    expect(f.pixelAt(30, 10), (0, 0, 255));
    expect(f.pixelAt(50, 10), (255, 0, 0));
    expect(f.pixelAt(70, 10), (0, 255, 255));
    // HSL and packed colors stay in the compact simple-raster path.
    expect(rt.lastOpCount, lessThanOrEqualTo(4));

    rt.setProperty('speed', 10);
    final overlay = await IsolatedHtmlEffectRuntime.load(
      effect(
        script: '''
var ctx = document.getElementById('exCanvas').getContext('2d');
ctx.fillStyle = '#000000';
ctx.fillRect(0, 0, 320, 200);
ctx.fillStyle = 'rgba(255, 0, 0, 0.5)';
ctx.fillRect(0, 0, 320, 200);
''',
      ),
    );
    addTearDown(overlay.dispose);
    final o = await overlay.renderFrame(0);
    final (r, g, b) = o.pixelAt(160, 100);
    expect(r, inInclusiveRange(120, 136));
    expect(g, lessThan(10));
    expect(b, lessThan(10));
  }, skip: _skip);

  test('decimal literals work under a comma decimal locale', () async {
    final setlocale = DynamicLibrary.process()
        .lookupFunction<
          Pointer<Utf8> Function(Int32, Pointer<Utf8>),
          Pointer<Utf8> Function(int, Pointer<Utf8>)
        >('setlocale');
    const lcNumeric = 1;
    final previous = setlocale(lcNumeric, nullptr).toDartString();
    final ptBr = 'pt_BR.utf8'.toNativeUtf8();
    final changed = setlocale(lcNumeric, ptBr);
    malloc.free(ptBr);
    if (changed.address == 0) {
      // The locale is not installed on this machine.
      return;
    }
    addTearDown(() {
      final back = previous.toNativeUtf8();
      setlocale(lcNumeric, back);
      malloc.free(back);
    });

    final rt = await IsolatedHtmlEffectRuntime.load(
      effect(
        script: '''
var ctx = document.getElementById('exCanvas').getContext('2d');
ctx.fillStyle = '#000000';
ctx.fillRect(0, 0, 320, 200);
ctx.globalAlpha = 0.5;
ctx.fillStyle = '#ff0000';
ctx.fillRect(0, 0, 320, 200);
''',
      ),
    );
    addTearDown(rt.dispose);
    final f = await rt.renderFrame(0);
    final (r, g, b) = f.pixelAt(160, 100);
    // Without the C numeric locale, 0.5 is parsed as 0 and the frame is black.
    expect(r, inInclusiveRange(120, 136));
    expect(g, lessThan(10));
    expect(b, lessThan(10));
  }, skip: _skip);

  test(
    'an effect stuck in a loop is interrupted by QuickJS',
    () async {
      final rt = await IsolatedHtmlEffectRuntime.load(
        effect(
          script: '''
var ctx = document.getElementById('exCanvas').getContext('2d');
function loop() { try { while (true) {} } catch (e) {} }
requestAnimationFrame(loop);
''',
        ),
      );
      addTearDown(rt.dispose);
      // The error must come from the worker (the native call returned), not
      // from the parent's hard limit: killing an isolate does not stop native
      // code, so a hard-limit error would mean the thread is still spinning.
      // The script's try/catch cannot swallow the interrupt.
      await expectLater(
        rt.renderFrame(0),
        throwsA(
          isA<EffectScriptException>().having(
            (e) => e.message,
            'message',
            allOf(contains('interrupted'), isNot(contains('excedeu'))),
          ),
        ),
      );
    },
    skip: _skip,
    timeout: const Timeout(Duration(seconds: 20)),
  );
}
