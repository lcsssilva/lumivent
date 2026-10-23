import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/lighting/infrastructure/html_effects/css_color.dart';
import 'package:lumivent/features/lighting/domain/effects/effect_meta.dart';

void main() {
  group('parseCssColor', () {
    test('short, long, and alpha hex values', () {
      expect(parseCssColor('#f00'), const Color(0xFFFF0000));
      expect(parseCssColor('#E383c0'), const Color(0xFFE383C0));
      expect(parseCssColor('#00ff0080'), const Color(0x8000FF00));
    });

    test('rgb and rgba', () {
      expect(parseCssColor('rgb(10, 20, 30)'), const Color(0xFF0A141E));
      expect(parseCssColor('rgba(255,0,0,0.5)'), const Color(0x80FF0000));
      expect(parseCssColor('rgb(0 0 255 / 50%)'), const Color(0x800000FF));
    });

    test('hsl with a negative hue, as Rainbow generates', () {
      expect(parseCssColor('hsl(0, 100%, 50%)'), const Color(0xFFFF0000));
      expect(parseCssColor('hsl(-240, 100%, 50%)'), const Color(0xFF00FF00));
      expect(parseCssColor('hsl(480, 100%, 50%)'), const Color(0xFF00FF00));
      expect(
        parseCssColor('hsla(230, 100%, 26%, .05)'),
        const Color(0x0D001685),
      );
    });

    test('invalid names and values', () {
      expect(parseCssColor('black'), const Color(0xFF000000));
      expect(parseCssColor('transparent'), const Color(0x00000000));
      expect(parseCssColor('nope'), isNull);
      expect(parseCssColor('#12'), isNull);
    });
  });

  test('parseEffect reads title, properties, and scripts', () {
    const html = '''
<head>
  <title>Rainbow</title>
  <meta description="Rainbow" />
  <meta publisher="Autor Y" />
  <meta property="speed" label="Rainbow Speed" type="number" min="0" max="100" default="50" />
  <meta property="vertical" label="Vertical" type="boolean" default="0" />
  <meta property="mode" label="Modo" type="combobox" values="A,B, C" default="B" />
</head>
<body><canvas id="exCanvas" width="320" height="200"></canvas></body>
<script>var a = 1;</script>
<script src="ignorado.js"></script>
<script>var b = 2;</script>
''';
    final e = parseEffect(html);
    expect(e.title, 'Rainbow');
    expect(e.description, 'Rainbow');
    expect(e.publisher, 'Autor Y');
    expect(
      [for (final p in e.properties) p.name],
      ['speed', 'vertical', 'mode'],
    );
    expect(e.properties[0].initialValue, 50);
    expect(e.properties[0].max, 100);
    expect(e.properties[1].initialValue, false);
    expect(e.properties[2].values, ['A', 'B', 'C']);
    expect(e.properties[2].initialValue, 'B');
    expect(e.script, contains('var a = 1;'));
    expect(e.script, contains('var b = 2;'));
  });
}
