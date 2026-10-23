part of 'canvas_replayer.dart';

class _CanvasGradient {
  _CanvasGradient.linear(this.args) : radial = false;
  _CanvasGradient.radial(this.args) : radial = true;

  final bool radial;
  final List<double> args;
  final stops = <(double, Color)>[];

  Shader shader() {
    final s = [...stops]..sort((a, b) => a.$1.compareTo(b.$1));
    final colors = s.isEmpty
        ? const [Color(0x00000000), Color(0x00000000)]
        : [for (final e in s) e.$2];
    final pos = s.isEmpty
        ? const [0.0, 1.0]
        : [for (final e in s) e.$1.clamp(0.0, 1.0)];
    if (colors.length == 1) {
      colors.add(colors.first);
      pos.add(1.0);
    }
    if (!radial) {
      return Gradient.linear(
        Offset(args[0], args[1]),
        Offset(args[2], args[3]),
        colors,
        pos,
      );
    }
    // createRadialGradient(x0,y0,r0, x1,y1,r1): Skia focuses at (x0,y0).
    return Gradient.radial(
      Offset(args[3], args[4]),
      args[5],
      colors,
      pos,
      TileMode.clamp,
      null,
      Offset(args[0], args[1]),
      args[2],
    );
  }
}
