import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/lighting/domain/effect_runtime.dart';
import 'package:lumivent/features/lighting/domain/effect_frame.dart';
import 'package:lumivent/features/lighting/domain/effect_runtime_factory.dart';
import 'package:lumivent/features/lighting/domain/light_device.dart';
import 'package:lumivent/features/lighting/domain/rgb.dart';

import 'fake_runtime.dart';

class FakeRuntimeFactory implements EffectRuntimeFactory {
  FakeRuntimeFactory({this.colors});

  final Map<LightDeviceId, List<Rgb>>? colors;
  int loads = 0;
  late FakeRuntime runtime;

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
    runtime = FakeRuntime(EffectFrame(320, 200, rgba), colors);
    return runtime;
  }
}
