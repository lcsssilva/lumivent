/// Point in local device coordinates, normalized to [0,1]².
class LedPoint {
  const LedPoint(this.x, this.y);
  final double x, y;

  @override
  String toString() => 'LedPoint($x, $y)';
}
