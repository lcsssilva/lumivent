import '../rgb.dart';

enum EffectParamType { number, color, boolean, combobox, hue }

/// Values saved by older versions, when the option text was Portuguese.
const _legacyOptions = {
  'Esquerda': 'Left',
  'Direita': 'Right',
  'Cima': 'Up',
  'Baixo': 'Down',
};

/// Effect parameter declaration.
class EffectParam {
  const EffectParam.number(
    this.id,
    this.label, {
    required double this.min,
    required double this.max,
    required double this.defaultValue,
  }) : type = EffectParamType.number,
       options = const [];

  const EffectParam.hue(this.id, this.label, {double this.defaultValue = 0})
    : type = EffectParamType.hue,
      min = 0,
      max = 360,
      options = const [];

  /// [defaultValue] in `#RRGGBB`.
  const EffectParam.color(
    this.id,
    this.label, {
    required String this.defaultValue,
  }) : type = EffectParamType.color,
       min = null,
       max = null,
       options = const [];

  const EffectParam.boolean(
    this.id,
    this.label, {
    bool this.defaultValue = false,
  }) : type = EffectParamType.boolean,
       min = null,
       max = null,
       options = const [];

  const EffectParam.combobox(
    this.id,
    this.label, {
    required this.options,
    required String this.defaultValue,
  }) : type = EffectParamType.combobox,
       min = null,
       max = null;

  final String id;
  final String label;
  final EffectParamType type;
  final double? min, max;

  /// `double` (number/hue), `String` `#RRGGBB` (color), `bool` or `String`.
  final Object defaultValue;
  final List<String> options;

  /// Valid value for [raw]; default if missing, wrongly typed, or (for numbers)
  /// non-finite. Numbers are clamped to min..max.
  Object resolve(Object? raw) {
    switch (type) {
      case EffectParamType.number:
      case EffectParamType.hue:
        final n = raw is num
            ? raw.toDouble()
            : (raw is String ? double.tryParse(raw) : null);
        if (n == null || !n.isFinite) return defaultValue;
        return n.clamp(min!, max!);
      case EffectParamType.color:
        final c = raw is String ? Rgb.parse(raw) : null;
        return (c ?? Rgb.parse(defaultValue as String)!).toHex();
      case EffectParamType.boolean:
        if (raw is bool) return raw;
        if (raw is num) return raw != 0;
        return defaultValue;
      case EffectParamType.combobox:
        final value = raw is String ? (_legacyOptions[raw] ?? raw) : null;
        return value != null && options.contains(value) ? value : defaultValue;
    }
  }
}
