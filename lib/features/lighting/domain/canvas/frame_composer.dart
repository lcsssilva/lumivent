// Lighting module domain (pure Dart): composes the LED frame.

import '../hardware_mode/hardware_equivalent.dart';
import '../hardware_mode/hardware_timing.dart';
import 'led_layout.dart';
import '../light_device.dart';
import '../config/lighting_config.dart';
import '../native_effects/native_effects.dart';
import '../effects/effect_values.dart';
import '../native_effects/native_effect.dart';
import '../rgb.dart';

/// Stateful composition helpers owned by one lighting engine.
///
/// The instance caches validated effect parameters; composition results
/// still depend only on the input config and time.
class FrameComposer {
  String? _cachedId;
  Map<String, Object?>? _cachedRaw;
  bool _cachedFixedSpeed = false;
  EffectValues? _cachedValues;

  Map<LightDeviceId, List<Rgb>> compose(
    LightingConfig config,
    double seconds, {
    double Function(LightDeviceId id)? timeFor,
    Set<LightDeviceId>? only,
    Map<LightDeviceId, List<Rgb>>? pixels,
  }) => composeFrame(
    config,
    seconds,
    timeFor: timeFor,
    only: only,
    pixels: pixels,
    composer: this,
  );

  Rgb averageCanvasColor(
    LightingConfig config,
    LightDeviceId id,
    double seconds, {
    double Function(LightDeviceId id)? timeFor,
    Map<LightDeviceId, List<Rgb>>? pixels,
  }) => composeAverageCanvasColor(
    config,
    id,
    seconds,
    timeFor: timeFor,
    pixels: pixels,
    composer: this,
  );

  EffectValues _valuesOf(LightingConfig config, NativeEffect effect) {
    final raw = config.effectValues[effect.id] ?? const <String, Object?>{};
    final fixedSpeed =
        firmwareSpeedFixed(config) &&
        effect.params.any((parameter) => parameter.id == 'speed');
    final cached = _cachedValues;
    if (cached != null &&
        _cachedId == effect.id &&
        identical(_cachedRaw, raw) &&
        _cachedFixedSpeed == fixedSpeed) {
      return cached;
    }
    final values = _buildValues(config, effect, raw, fixedSpeed);
    _cachedId = effect.id;
    _cachedRaw = raw;
    _cachedFixedSpeed = fixedSpeed;
    return _cachedValues = values;
  }
}

/// Colors of each device in canvas or fixed-color mode at instant [t]
/// (seconds). Devices in hardware mode and the GPU are kept off the map (the
/// driver handles them). Disabled (`enabled == false`) or `argbOff` = everything
/// black. Unknown effect (e.g. HTML, evaluated by the engine) = black.
///
/// [timeFor] evaluates a device at its own instant instead of [t] (latency
/// compensation: a slow output gets the colors of the future it will show them
/// in). [only] restricts the result to those devices, so the engine can compose
/// one output family at a time.
///
/// [pixels] are colors already sampled from an HTML effect frame (plan
/// §5.5), keyed by device. They are used for canvas devices when the global
/// effect has no native evaluator.
Map<LightDeviceId, List<Rgb>> composeFrame(
  LightingConfig c,
  double t, {
  double Function(LightDeviceId id)? timeFor,
  Set<LightDeviceId>? only,
  Map<LightDeviceId, List<Rgb>>? pixels,
  FrameComposer? composer,
}) {
  final effect = nativeEffectById(c.effectId);
  final values = effect == null
      ? null
      : composer?._valuesOf(c, effect) ?? _buildValues(c, effect);
  final out = <LightDeviceId, List<Rgb>>{};

  for (final id in LightDeviceId.values) {
    if (!id.isSupported || (only != null && !only.contains(id))) continue;
    final d = c.device(id);
    if (d.mode == LightMode.hardware) continue;

    final layout = ledLayoutFor(id, fanQuantity: c.fansOf(id));
    if (layout.length == 0) continue;
    final n = layout.length;
    final off = !d.enabled || c.argbOff;
    final dt = timeFor?.call(id) ?? t;
    final list = List<Rgb>.filled(n, Rgb.black);
    if (!off) {
      if (d.mode == LightMode.fixed) {
        list.fillRange(0, n, d.fixedColor.scaled(c.brightness));
      } else if (effect != null && values != null) {
        for (var i = 0; i < n; i++) {
          final (x, y) = d.placement.map(layout.leds[i]);
          list[i] = effect.colorAt(x, y, dt, values).scaled(c.brightness);
        }
      } else {
        final sampled = pixels?[id];
        if (sampled != null && sampled.length == n) {
          for (var i = 0; i < n; i++) {
            list[i] = sampled[i].scaled(c.brightness);
          }
        }
      }
    }
    out[id] = list;
  }
  return out;
}

/// Average color of [id]'s canvas rectangle at [t]. Used by the GPU, which has
/// a single hardware color instead of addressable LEDs.
///
/// The color is **not** scaled by the global brightness: the GPU packet carries
/// its own brightness level, so scaling here would apply it twice. Fixed mode
/// returns the fixed color; a disabled/off device or an unknown effect returns
/// black. [pixels] (HTML effect frames) are used when the effect has no native
/// evaluator.
Rgb averageCanvasColor(
  LightingConfig c,
  LightDeviceId id,
  double t, {
  double Function(LightDeviceId id)? timeFor,
  Map<LightDeviceId, List<Rgb>>? pixels,
}) => composeAverageCanvasColor(c, id, t, timeFor: timeFor, pixels: pixels);

Rgb composeAverageCanvasColor(
  LightingConfig c,
  LightDeviceId id,
  double t, {
  double Function(LightDeviceId id)? timeFor,
  Map<LightDeviceId, List<Rgb>>? pixels,
  FrameComposer? composer,
}) {
  if (!id.isSupported || c.argbOff) return Rgb.black;
  final d = c.device(id);
  if (!d.enabled || d.mode == LightMode.hardware) return Rgb.black;
  if (d.mode == LightMode.fixed) return d.fixedColor;

  final dt = timeFor?.call(id) ?? t;
  final effect = nativeEffectById(c.effectId);
  final values = effect == null
      ? null
      : composer?._valuesOf(c, effect) ?? _buildValues(c, effect);
  if (effect != null && values != null) {
    // A grid over the placed rectangle; 96 samples are enough for a smooth
    // average and cheap at the GPU lane's ~8 sends/s.
    const cols = 12, rows = 8;
    final rect = d.placement;
    var r = 0, g = 0, b = 0;
    for (var iy = 0; iy < rows; iy++) {
      final y = rect.y + (iy + 0.5) * rect.h / rows;
      for (var ix = 0; ix < cols; ix++) {
        final x = rect.x + (ix + 0.5) * rect.w / cols;
        final color = effect.colorAt(x, y, dt, values);
        r += color.r;
        g += color.g;
        b += color.b;
      }
    }
    final n = cols * rows;
    return Rgb((r / n).round(), (g / n).round(), (b / n).round());
  }

  final sampled = pixels?[id];
  if (sampled == null || sampled.isEmpty) return Rgb.black;
  var r = 0, g = 0, b = 0;
  for (final color in sampled) {
    r += color.r;
    g += color.g;
    b += color.b;
  }
  final n = sampled.length;
  return Rgb((r / n).round(), (g / n).round(), (b / n).round());
}

EffectValues _buildValues(
  LightingConfig c,
  NativeEffect effect, [
  Map<String, Object?>? raw,
  bool? fixedSpeed,
]) {
  raw ??= c.effectValues[effect.id] ?? const <String, Object?>{};
  // Scan has no speed in the firmware: the canvas follows the
  // firmware's fixed pace instead of the slider.
  fixedSpeed ??=
      firmwareSpeedFixed(c) && effect.params.any((p) => p.id == 'speed');
  return effect.valuesFrom(
    fixedSpeed ? {...raw, 'speed': firmwareFixedEffectSpeed} : raw,
  );
}
