import 'rgb.dart';

class EffectProperty {
  EffectProperty({
    required this.name,
    required this.type,
    this.label,
    this.min,
    this.max,
    this.defaultValue,
    this.values = const [],
  });

  final String name;

  /// number, color, boolean, combobox, hue, textfield, sensor
  final String type;
  final String? label;
  final num? min, max;
  final String? defaultValue;
  final List<String> values;

  /// Initial value of the JS global variable with the property's name.
  Object? get initialValue {
    final d = defaultValue;
    switch (type) {
      case 'number':
      case 'hue':
        return num.tryParse(d ?? '') ?? min ?? 0;
      case 'boolean':
        return d == '1' || d == 'true';
      case 'combobox':
        return d ?? (values.isEmpty ? '' : values.first);
      default:
        return d ?? '';
    }
  }

  /// [raw] validated for this property: default when missing or wrongly typed,
  /// numbers clamped to min..max, comboboxes restricted to [values]. Colors
  /// stay as CSS strings (the effect script parses them).
  Object? resolve(Object? raw) {
    switch (type) {
      case 'number':
      case 'hue':
        return verifyNumberAndHue(raw);
      case 'boolean':
        return verifyBoolean(raw);
      case 'combobox':
        return verifyCombobox(raw);
      case 'color':
        return verifyColor(raw);
      default:
        return raw is String ? raw : initialValue;
    }
  }

  Object? verifyBoolean(Object? raw) {
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    return initialValue;
  }

  Object? verifyNumberAndHue(Object? raw) {
    final n = raw is num
        ? raw.toDouble()
        : (raw is String ? double.tryParse(raw) : null);
    final fallback =
        num.tryParse(defaultValue ?? '')?.toDouble() ?? (min?.toDouble() ?? 0);
    if (n == null || !n.isFinite) return fallback;
    final lo = min?.toDouble(), hi = max?.toDouble();
    return n.clamp(lo ?? n, hi ?? n);
  }

  Object? verifyCombobox(Object? raw) {
    if (raw is String && (values.isEmpty || values.contains(raw))) {
      return raw;
    }
    return initialValue;
  }

  Object? verifyColor(Object? raw) {
    if (raw is String && Rgb.parse(raw) != null) {
      return Rgb.parse(raw)!.toHex();
    }
    final d = defaultValue;
    if (d != null && Rgb.parse(d) != null) return Rgb.parse(d)!.toHex();
    return '#FFFFFF';
  }
}
