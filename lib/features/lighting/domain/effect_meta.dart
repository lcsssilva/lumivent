// Reads an HTML/Canvas effect (HTML + JS): title, description, author,
// `<meta property>` values, and `<script>` code.
//
// Parsing is pure Dart (package:html), so the presentation can show the
// generated controls without touching the effect runtime.

import 'package:html/parser.dart' as html;

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
        final n = raw is num
            ? raw.toDouble()
            : (raw is String ? double.tryParse(raw) : null);
        final fallback =
            num.tryParse(defaultValue ?? '')?.toDouble() ??
            (min?.toDouble() ?? 0);
        if (n == null || !n.isFinite) return fallback;
        final lo = min?.toDouble(), hi = max?.toDouble();
        return n.clamp(lo ?? n, hi ?? n);
      case 'boolean':
        if (raw is bool) return raw;
        if (raw is num) return raw != 0;
        return initialValue;
      case 'combobox':
        if (raw is String && (values.isEmpty || values.contains(raw))) {
          return raw;
        }
        return initialValue;
      case 'color':
        if (raw is String && Rgb.parse(raw) != null) {
          return Rgb.parse(raw)!.toHex();
        }
        final d = defaultValue;
        if (d != null && Rgb.parse(d) != null) return Rgb.parse(d)!.toHex();
        return '#FFFFFF';
      default:
        return raw is String ? raw : initialValue;
    }
  }
}

class EffectSource {
  EffectSource({
    required this.title,
    required this.properties,
    required this.script,
    this.description,
    this.publisher,
  });

  final String title;
  final String? description, publisher;
  final List<EffectProperty> properties;

  /// All inline `<script>` blocks, in document order.
  final String script;
}

EffectSource parseEffect(String source) {
  final doc = html.parse(source);
  String? metaAttr(String attr) =>
      doc.querySelector('meta[$attr]')?.attributes[attr];

  final props = <EffectProperty>[
    for (final m in doc.querySelectorAll('meta[property]'))
      EffectProperty(
        name: m.attributes['property']!,
        type: m.attributes['type'] ?? 'textfield',
        label: m.attributes['label'],
        min: num.tryParse(m.attributes['min'] ?? ''),
        max: num.tryParse(m.attributes['max'] ?? ''),
        defaultValue: m.attributes['default'],
        values: _splitValues(m.attributes['values']),
      ),
  ];

  final scripts = [
    for (final s in doc.querySelectorAll('script'))
      if (!s.attributes.containsKey('src')) s.text,
  ];

  return EffectSource(
    title: doc.querySelector('title')?.text.trim() ?? 'Untitled',
    description: metaAttr('description'),
    publisher: metaAttr('publisher'),
    properties: props,
    script: scripts.join('\n;\n'),
  );
}

List<String> _splitValues(String? v) => v == null
    ? const []
    : [
        for (final s in v.split(','))
          if (s.trim().isNotEmpty) s.trim(),
      ];
