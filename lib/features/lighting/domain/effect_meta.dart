// Reads an HTML/Canvas effect (HTML + JS): title, description, author,
// `<meta property>` values, and `<script>` code.
//
// Parsing is pure Dart (package:html), so the presentation can show the
// generated controls without touching the effect runtime.

import 'package:html/parser.dart' as html;

import 'effect_property.dart';
import 'effect_source.dart';

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
