import 'rgb.dart';
import 'native_effects.dart';
import 'effect_values.dart';

/// Native effect: [colorAt] returns the LED color in (x, y) of the canvas
/// (0..320 × 0..200) at time [t] (seconds).
class NativeEffect {
  const NativeEffect(this.id, this.name, this.params, this._fn);

  final String id;
  final String name;
  final List<EffectParam> params;
  final EffectFn _fn;

  Rgb colorAt(double x, double y, double t, EffectValues v) => _fn(x, y, t, v);

  EffectValues valuesFrom(Map<String, Object?> raw) =>
      EffectValues(params, raw);
}
