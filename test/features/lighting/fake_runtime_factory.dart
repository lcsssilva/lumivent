part of 'html_effect_runner_test.dart';

class _FakeRuntimeFactory implements EffectRuntimeFactory {
  _FakeRuntimeFactory({this.colors});

  final Map<LightDeviceId, List<Rgb>>? colors;
  int loads = 0;
  late _FakeRuntime runtime;

  @override
  Future<EffectRuntime> load(
    String html, {
    Map<String, Object?> values = const {},
  }) async {
    loads++;
    final rgba = Uint8List(320 * 200 * 4);
    for (var i = 0; i < rgba.length; i += 4) {
      rgba[i] = 30;
      rgba[i + 1] = 60;
      rgba[i + 2] = 90;
      rgba[i + 3] = 255;
    }
    runtime = _FakeRuntime(EffectFrame(320, 200, rgba), colors);
    return runtime;
  }
}
