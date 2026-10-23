/// Curve phase already expressed in RPM (`RPMConfig` in the protocol notes).
class RpmPhase {
  const RpmPhase(this.temp, this.rpm);
  final double temp;
  final int rpm;

  @override
  bool operator ==(Object other) =>
      other is RpmPhase && other.temp == temp && other.rpm == rpm;

  @override
  int get hashCode => Object.hash(temp, rpm);

  @override
  String toString() => 'RpmPhase($temp °C, $rpm rpm)';
}
