// CSS color parser used by the Canvas2D shim: #hex, rgb()/rgba(),
// hsl()/hsla() and common color names. Invalid color → null (Canvas2D ignores
// the assignment in that case).
import 'dart:ui';

const _named = <String, int>{
  'transparent': 0x00000000,
  'black': 0xFF000000,
  'white': 0xFFFFFFFF,
  'red': 0xFFFF0000,
  'lime': 0xFF00FF00,
  'green': 0xFF008000,
  'blue': 0xFF0000FF,
  'yellow': 0xFFFFFF00,
  'cyan': 0xFF00FFFF,
  'aqua': 0xFF00FFFF,
  'magenta': 0xFFFF00FF,
  'fuchsia': 0xFFFF00FF,
  'orange': 0xFFFFA500,
  'purple': 0xFF800080,
  'pink': 0xFFFFC0CB,
  'gray': 0xFF808080,
  'grey': 0xFF808080,
  'silver': 0xFFC0C0C0,
  'maroon': 0xFF800000,
  'navy': 0xFF000080,
  'teal': 0xFF008080,
  'olive': 0xFF808000,
  'violet': 0xFFEE82EE,
  'indigo': 0xFF4B0082,
  'gold': 0xFFFFD700,
};

final _fn = RegExp(r'^(rgba?|hsla?)\((.*)\)$');

Color? parseCssColor(String input) {
  final s = input.trim().toLowerCase();
  if (s.startsWith('#')) return _hex(s.substring(1));
  final named = _named[s];
  if (named != null) return Color(named);
  final m = _fn.firstMatch(s);
  if (m == null) return null;
  // Accepts "a, b, c, d", "a b c / d" and mixtures.
  final parts = m
      .group(2)!
      .split(RegExp(r'[\s,/]+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.length < 3) return null;
  final alpha = parts.length > 3 ? _alpha(parts[3]) : 1.0;
  if (alpha == null) return null;
  if (m.group(1)!.startsWith('rgb')) {
    final c = [for (final p in parts.take(3)) _channel(p)];
    if (c.contains(null)) return null;
    return Color.fromARGB((alpha * 255).round(), c[0]!, c[1]!, c[2]!);
  }
  final h = _hue(parts[0]), sat = _percent(parts[1]), l = _percent(parts[2]);
  if (h == null || sat == null || l == null) return null;
  return _hsl(h, sat, l, alpha);
}

Color? _hex(String h) {
  if (!RegExp(r'^[0-9a-f]+$').hasMatch(h)) return null;
  switch (h.length) {
    case 3:
    case 4:
      final v = [for (final c in h.split('')) int.parse(c * 2, radix: 16)];
      return Color.fromARGB(h.length == 4 ? v[3] : 255, v[0], v[1], v[2]);
    case 6:
      return Color(0xFF000000 | int.parse(h, radix: 16));
    case 8:
      final v = int.parse(h, radix: 16);
      return Color(((v & 0xFF) << 24) | (v >> 8));
  }
  return null;
}

int? _channel(String p) {
  final v = p.endsWith('%')
      ? double.tryParse(p.substring(0, p.length - 1))?.let((x) => x * 2.55)
      : double.tryParse(p);
  return v?.round().clamp(0, 255);
}

double? _alpha(String p) {
  final v = p.endsWith('%')
      ? double.tryParse(p.substring(0, p.length - 1))?.let((x) => x / 100)
      : double.tryParse(p);
  return v?.clamp(0.0, 1.0);
}

double? _percent(String p) {
  final v = double.tryParse(p.endsWith('%') ? p.substring(0, p.length - 1) : p);
  return v?.clamp(0.0, 100.0).let((x) => x / 100);
}

double? _hue(String p) {
  final v = double.tryParse(p.replaceAll('deg', ''));
  if (v == null || !v.isFinite) return null;
  // CSS accepts negative hue or values above 360 (Rainbow produces both).
  final h = v % 360;
  return h < 0 ? h + 360 : h;
}

Color _hsl(double h, double s, double l, double a) {
  final c = (1 - (2 * l - 1).abs()) * s;
  final hp = h / 60;
  final x = c * (1 - (hp % 2 - 1).abs());
  final (r1, g1, b1) = switch (hp.floor()) {
    0 => (c, x, 0.0),
    1 => (x, c, 0.0),
    2 => (0.0, c, x),
    3 => (0.0, x, c),
    4 => (x, 0.0, c),
    _ => (c, 0.0, x),
  };
  final m = l - c / 2;
  int ch(double v) => ((v + m) * 255).round().clamp(0, 255);
  return Color.fromARGB((a * 255).round(), ch(r1), ch(g1), ch(b1));
}

extension<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
