// Lighting module domain (pure Dart): immutable 8-bit RGB color.

import 'dart:math' as math;

class Rgb {
  const Rgb(this.r, this.g, this.b)
    : assert(r >= 0 && r <= 255),
      assert(g >= 0 && g <= 255),
      assert(b >= 0 && b <= 255);

  static const black = Rgb(0, 0, 0);
  static const white = Rgb(255, 255, 255);

  final int r, g, b;

  /// Multiplies channels by [f] (typically 0–1); floors and
  /// clamps to 0–255.
  Rgb scaled(double f) {
    if (f.isNaN || f <= 0) return black;
    int s(int c) => (c * f).floor().clamp(0, 255);
    return Rgb(s(r), s(g), s(b));
  }

  /// Linearly interpolates from [a] (t = 0) to [b] (t = 1); [t] is clamped to 0–1.
  static Rgb lerp(Rgb a, Rgb b, double t) {
    if (t.isNaN || t <= 0) return a;
    if (t >= 1) return b;
    int m(int x, int y) => (x + (y - x) * t).round().clamp(0, 255);
    return Rgb(m(a.r, b.r), m(a.g, b.g), m(a.b, b.b));
  }

  /// [h] in degrees (any value, normalized to 0–360); [s] and [v] in 0–1.
  factory Rgb.fromHsv(double h, double s, double v) {
    s = s.clamp(0.0, 1.0);
    v = v.clamp(0.0, 1.0);
    final hh = (h % 360) / 60;
    final i = hh.floor() % 6;
    final f = hh - hh.floor();
    final p = v * (1 - s), q = v * (1 - s * f), t = v * (1 - s * (1 - f));
    final (r, g, b) = switch (i) {
      0 => (v, t, p),
      1 => (q, v, p),
      2 => (p, v, t),
      3 => (p, q, v),
      4 => (t, p, v),
      _ => (v, p, q),
    };
    int c(double x) => (x * 255).round().clamp(0, 255);
    return Rgb(c(r), c(g), c(b));
  }

  /// Uppercase `#RRGGBB`.
  String toHex() {
    String h(int c) => c.toRadixString(16).padLeft(2, '0').toUpperCase();
    return '#${h(r)}${h(g)}${h(b)}';
  }

  /// Reads `#RRGGBB` or `#RGB` (`#` is optional). `null` if invalid.
  static Rgb? parse(String? text) {
    if (text == null) return null;
    var s = text.trim();
    if (s.startsWith('#')) s = s.substring(1);
    if (s.length == 3) s = s.split('').map((c) => '$c$c').join();
    if (s.length != 6 || !RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(s)) return null;
    final v = int.parse(s, radix: 16);
    return Rgb((v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF);
  }

  /// Largest channel, useful for limiting brightness.
  int get maxChannel => math.max(r, math.max(g, b));

  @override
  bool operator ==(Object other) =>
      other is Rgb && other.r == r && other.g == g && other.b == b;

  @override
  int get hashCode => Object.hash(r, g, b);

  @override
  String toString() => 'Rgb(${toHex()})';
}
