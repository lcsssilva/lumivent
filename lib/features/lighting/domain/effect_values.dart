import 'rgb.dart';
import 'native_effects.dart';

/// Validated parameter values for an effect.
class EffectValues {
  EffectValues(List<EffectParam> params, [Map<String, Object?> raw = const {}])
    : _v = {
        for (final p in params)
          p.id: p.type == EffectParamType.color
              ? Rgb.parse(p.resolve(raw[p.id]) as String)!
              : p.resolve(raw[p.id]),
      };

  final Map<String, Object> _v;

  double number(String id) => _v[id] as double;
  Rgb color(String id) => _v[id] as Rgb;
  bool boolean(String id) => _v[id] as bool;
  String option(String id) => _v[id] as String;
}
