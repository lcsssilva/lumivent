// Lighting module domain (pure Dart): port of the HTML effect runtime.
//
// The implementation runs QuickJS in a worker isolate and replays its canvas
// commands on the UI isolate, returning a plain RGBA frame; the application
// samples the LEDs from it and sends the colors to the engine.

import 'dart:typed_data';

import 'effect_source.dart';
import '../canvas/effect_sampling.dart';
import '../light_device.dart';
import '../rgb.dart';
import '../canvas/effect_frame.dart';

/// A loaded effect. All methods run on the UI isolate; [dispose] is mandatory.
abstract interface class EffectRuntime {
  /// The effect metadata (title, properties, script).
  EffectSource get effect;

  /// Runs `requestAnimationFrame`/timers up to [nowMs] and returns the frame.
  Future<EffectFrame> renderFrame(double nowMs);

  /// Applies a property value (the JS global with the same name) and calls
  /// `on<name>Changed` when the effect defines it.
  void setProperty(String name, Object? value);

  /// Pins where the frame is sampled: one `(device, x, y)` per LED, in canvas
  /// pixels, in driver order ([canvasSamplePoints] builds them). Once set,
  /// [renderSampled] returns the device colors for every frame, computed on
  /// the render isolate itself. A change replaces the points; `null` stops
  /// the sampling.
  void setSamplePoints(List<(LightDeviceId, int, int)>? points);

  /// Renders the frame at [nowMs], together with the device colors sampled on
  /// the render isolate ([setSamplePoints]); `null` colors mean this runtime
  /// did not sample (and the app samples from the returned frame itself).
  ///
  /// With [needFrame] false (no preview or thumbnail is waiting for the
  /// pixels) a runtime that sampled the colors may skip transferring the
  /// frame and return `null` for it. The frame is never `null` when the
  /// colors are.
  Future<(EffectFrame?, Map<LightDeviceId, List<Rgb>>?)> renderSampled(
    double nowMs, {
    bool needFrame = true,
  });

  /// Values for `engine.getSensorValue` (metric id → reading).
  void setSensors(Map<String, double> values);

  /// PNG of the last frame, for the Explore thumbnail; `null` before the first.
  Future<Uint8List?> snapshotPng();

  /// Everything the script logged since the last call.
  List<String> drainLog();

  /// Canvas operations the replay did not understand (compatibility hint).
  Set<String> get unknownOps;

  void dispose();
}
