import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/lighting/domain/effects/effect_source.dart';
import 'package:lumivent/features/lighting/domain/effects/effect_runtime.dart';
import 'package:lumivent/features/lighting/domain/canvas/effect_frame.dart';
import 'package:lumivent/features/lighting/domain/light_device.dart';
import 'package:lumivent/features/lighting/domain/rgb.dart';

class FakeRuntime implements EffectRuntime {
  FakeRuntime(this._frame, this._colors);

  final EffectFrame _frame;

  /// Colors "sampled on the worker"; `null` makes the runner sample itself.
  final Map<LightDeviceId, List<Rgb>>? _colors;

  /// `needFrame` of every render, in order.
  final frameRequests = <bool>[];
  final properties = <String, Object?>{};
  final sensors = <String, double>{};
  bool disposed = false;

  @override
  EffectSource get effect =>
      EffectSource(title: 'Teste', properties: const [], script: '');

  @override
  Future<(EffectFrame?, Map<LightDeviceId, List<Rgb>>?)> renderSampled(
    double nowMs, {
    bool needFrame = true,
  }) async {
    frameRequests.add(needFrame);
    final colors = _colors;
    return (needFrame || colors == null ? _frame : null, colors);
  }

  @override
  void setSamplePoints(List<(LightDeviceId, int, int)>? points) {}

  @override
  Future<EffectFrame> renderFrame(double nowMs) async => _frame;

  @override
  void setProperty(String name, Object? value) => properties[name] = value;

  @override
  void setSensors(Map<String, double> values) => sensors.addAll(values);

  @override
  Future<Uint8List?> snapshotPng() async => null;

  @override
  List<String> drainLog() => const [];

  @override
  Set<String> get unknownOps => const {};

  @override
  void dispose() => disposed = true;
}
