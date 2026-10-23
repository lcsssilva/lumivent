/// Editable curve point: temperature (°C, 0–100) → speed as a percentage of
/// the fan size's maximum RPM.
class FanPoint {
  const FanPoint(this.temp, this.percent);
  final double temp;
  final double percent;

  @override
  bool operator ==(Object other) =>
      other is FanPoint && other.temp == temp && other.percent == percent;

  @override
  int get hashCode => Object.hash(temp, percent);

  @override
  String toString() => 'FanPoint($temp °C, $percent %)';
}
