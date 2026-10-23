/// Result of one smoothing step.
class FanStep {
  const FanStep({
    required this.temp,
    required this.targetRpm,
    required this.duty,
  });

  /// Average temperature used by the curve.
  final double temp;

  /// RPM the curve requests at that temperature.
  final int targetRpm;

  /// Duty to send, already limited by the ramp (1 = start/stop stop state).
  final int duty;
}
