// HSL→ARGB used when the shim forwards `hsl()` colors as three numbers instead
// of packing them in JS (QuickJS is slow at the per-color math).

int hslArgb(double hDeg, double sPct, double lPct) {
  // Non-finite components count as 0, like the shim's own HSL parser.
  if (!hDeg.isFinite) hDeg = 0;
  if (!sPct.isFinite) sPct = 0;
  if (!lPct.isFinite) lPct = 0;
  var h = hDeg % 360;
  if (h < 0) h += 360;
  h /= 360;
  var s = sPct.clamp(0, 100) / 100;
  var l = lPct.clamp(0, 100) / 100;
  double r, g, b;
  if (s == 0) {
    r = g = b = l;
  } else {
    final q = l < 0.5 ? l * (1 + s) : l + s - l * s;
    final p = 2 * l - q;
    double hue(double t) {
      if (t < 0) t += 1;
      if (t > 1) t -= 1;
      if (t < 1 / 6) return p + (q - p) * 6 * t;
      if (t < 1 / 2) return q;
      if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
      return p;
    }

    r = hue(h + 1 / 3);
    g = hue(h);
    b = hue(h - 1 / 3);
  }
  final ri = (r * 255).round().clamp(0, 255);
  final gi = (g * 255).round().clamp(0, 255);
  final bi = (b * 255).round().clamp(0, 255);
  return 0xff000000 | (ri << 16) | (gi << 8) | bi;
}
