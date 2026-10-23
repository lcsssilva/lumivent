/// Group state from the last loop cycle.
class FanGroupStatus {
  const FanGroupStatus({
    required this.group,
    this.temp,
    this.rawTemp,
    this.targetRpm,
    this.duty,
  });
  final int group;

  /// Average temperature (used by the curve); `null` = no reading (group is not
  /// updated).
  final double? temp;

  /// Raw source reading in this cycle.
  final double? rawTemp;

  /// RPM the curve requests now.
  final int? targetRpm;

  /// Duty sent (after ramping); `null` if nothing was sent (no
  /// temperature or hub missing).
  final int? duty;
}
