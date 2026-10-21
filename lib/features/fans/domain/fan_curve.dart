// Fans module domain (pure Dart): AL V2 fan speed curves,
// as the vendor software calculates them (`AL-V2-protocolo.md` §5).

import 'dart:math' as math;

/// Fan size: defines os limites de RPM da curva.
enum FanSize {
  mm120(maxRpm: 2000, minRpm: 250),
  mm140(maxRpm: 1600, minRpm: 200);

  const FanSize({required this.maxRpm, required this.minRpm});
  final int maxRpm;
  final int minRpm;
}

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

/// Curve preset. [custom] is what a factory preset becomes when edited.
enum FanPreset {
  quiet,
  standard,
  high,
  full,
  fixed,
  user1,
  user2,
  user3,
  user4,
  custom;

  /// Quiet, Standard, High, and Full: factory points; editing turns them into [custom].
  bool get isBuiltIn =>
      this == quiet || this == standard || this == high || this == full;
  bool get isUser =>
      this == user1 || this == user2 || this == user3 || this == user4;
}

abstract final class FanPresets {
  /// Limit for editable points (not counting automatic endpoints).
  static const maxPoints = 8;

  static const defaultFixedPercent = 50.0;

  // `Ene6K77FanProfile.defaultPhaseData` (AL-V2 §5).
  static const quiet = [
    FanPoint(25, 20),
    FanPoint(45, 45),
    FanPoint(65, 52),
    FanPoint(80, 75),
    FanPoint(90, 100),
  ];
  static const standard = [
    FanPoint(25, 20),
    FanPoint(40, 50),
    FanPoint(55, 62),
    FanPoint(70, 75),
    FanPoint(90, 100),
  ];
  static const high = [
    FanPoint(25, 45),
    FanPoint(35, 55),
    FanPoint(50, 70),
    FanPoint(70, 85),
    FanPoint(85, 100),
  ];
  static const full = [
    FanPoint(25, 100),
    FanPoint(40, 100),
    FanPoint(55, 100),
    FanPoint(70, 100),
    FanPoint(90, 100),
  ];

  /// Factory points for a preset. UserDefine 1–4 start equal to Quiet;
  /// [FanPreset.fixed] and [FanPreset.custom] have no factory points.
  static List<FanPoint> defaults(FanPreset p) => switch (p) {
    FanPreset.quiet ||
    FanPreset.user1 ||
    FanPreset.user2 ||
    FanPreset.user3 ||
    FanPreset.user4 => quiet,
    FanPreset.standard => standard,
    FanPreset.high => high,
    FanPreset.full => full,
    FanPreset.fixed || FanPreset.custom => standard,
  };
}

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

int _rpmOf(double percent, FanSize size) =>
    (percent / 100 * size.maxRpm).round();

/// `RPMPhaseInfo.ToRPMConfigPhases`: percentage points → RPM phases, with
/// automatic endpoints. Without start/stop: `(0 °C, Min)` + points +
/// `(100 °C, Max)`. With start/stop: `(first point T, 0 RPM)` + points +
/// `(100 °C, Max)`, so the fan stops below the first point.
List<RpmPhase> toRpmPhases(
  List<FanPoint> points,
  FanSize size, {
  required bool startStop,
}) {
  final sorted = [...points]..sort((a, b) => a.temp.compareTo(b.temp));
  final first = sorted.isEmpty ? null : sorted.first;
  return [
    if (startStop && first != null)
      RpmPhase(first.temp, 0)
    else
      RpmPhase(0, size.minRpm),
    for (final p in sorted) RpmPhase(p.temp, _rpmOf(p.percent, size)),
    RpmPhase(100, size.maxRpm),
  ];
}

/// Constant curve for Fixed mode (one point, without endpoints).
List<RpmPhase> fixedRpmPhases(double percent, FanSize size) {
  final rpm = _rpmOf(percent, size);
  return [RpmPhase(0, rpm), RpmPhase(100, rpm)];
}

/// `RPMConfig.CalculateSpeed`: piecewise linear interpolation, clamped to the
/// first and last phases, never negative. Phases with the same temperature
/// (the start/stop step) take effect at that temperature.
int calculateSpeed(List<RpmPhase> phases, double temp) {
  if (phases.isEmpty) return 0;
  if (temp <= phases.first.temp) return math.max(0, phases.first.rpm);
  if (temp >= phases.last.temp) return math.max(0, phases.last.rpm);
  for (var i = 0; i < phases.length - 1; i++) {
    final a = phases[i], b = phases[i + 1];
    if (temp >= b.temp) continue;
    final dx = b.temp - a.temp;
    final rpm = dx <= 0
        ? b.rpm
        : a.rpm + (b.rpm - a.rpm) * (temp - a.temp) / dx;
    return math.max(0, rpm.round());
  }
  return math.max(0, phases.last.rpm);
}

/// Duty (%) sent to the hub: `rpm == 0 ? 1 : max(10, round(rpm / Max × 100))`.
/// Duty 1 is the firmware stop value (start/stop).
int dutyFor(int rpm, FanSize size) {
  if (rpm <= 0) return 1;
  return math.min(100, math.max(10, (rpm / size.maxRpm * 100).round()));
}
