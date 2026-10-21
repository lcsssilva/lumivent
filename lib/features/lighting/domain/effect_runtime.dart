// Lighting module domain (pure Dart): port of the HTML effect runtime.
//
// The implementation runs QuickJS in a worker isolate and replays its canvas
// commands on the UI isolate, returning a plain RGBA frame; the application
// samples the LEDs from it and sends the colors to the engine.

import 'dart:typed_data';

import 'effect_meta.dart';

/// One rendered canvas frame: `width × height` pixels in RGBA order.
class EffectFrame {
  const EffectFrame(this.width, this.height, this.rgba);

  final int width, height;
  final Uint8List rgba;

  /// Pixel [x], [y] (clamped to the frame), as 0–255 channels.
  (int, int, int) pixelAt(int x, int y) {
    final ix = x.clamp(0, width - 1);
    final iy = y.clamp(0, height - 1);
    final o = (iy * width + ix) * 4;
    return (rgba[o], rgba[o + 1], rgba[o + 2]);
  }
}

/// A loaded effect. All methods run on the UI isolate; [dispose] is mandatory.
abstract interface class EffectRuntime {
  /// The effect metadata (title, properties, script).
  EffectSource get effect;

  /// Runs `requestAnimationFrame`/timers up to [nowMs] and returns the frame.
  Future<EffectFrame> renderFrame(double nowMs);

  /// Applies a property value (the JS global with the same name) and calls
  /// `on<name>Changed` when the effect defines it.
  void setProperty(String name, Object? value);

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

/// Creates a runtime from the effect HTML (an isolate-safe port: the
/// implementation lives in lighting/infrastructure/html_effects).
abstract interface class EffectRuntimeFactory {
  Future<EffectRuntime> load(
    String html, {
    Map<String, Object?> values = const {},
  });
}
