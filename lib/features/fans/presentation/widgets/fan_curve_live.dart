/// Live data the editor draws on top of the curve.
class FanCurveLive {
  const FanCurveLive({
    this.temp,
    this.rpm,
    this.duty,
    this.tempLabel,
    this.trace = const [],
  });

  /// Current source temperature, in °C.
  final double? temp;

  /// Current group RPM.
  final double? rpm;

  /// Duty sent during the last cycle.
  final int? duty;

  /// Temperature already formatted in the user's unit (°C/°F).
  final String? tempLabel;

  /// Last ~60 seconds as pairs (°C, RPM). Missing readings are excluded.
  final List<({double temp, double rpm})> trace;
}
