/// One color in device order.
class GpuRgb {
  const GpuRgb(this.r, this.g, this.b)
    : assert(r >= 0 && r <= 255),
      assert(g >= 0 && g <= 255),
      assert(b >= 0 && b <= 255);

  static const black = GpuRgb(0, 0, 0);

  final int r, g, b;

  @override
  bool operator ==(Object other) =>
      other is GpuRgb && other.r == r && other.g == g && other.b == b;

  @override
  int get hashCode => Object.hash(r, g, b);

  @override
  String toString() => 'GpuRgb($r,$g,$b)';
}
