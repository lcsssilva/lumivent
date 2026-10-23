// Fans module domain (pure Dart): AL V2 fan speed curves,
// as the vendor software calculates them (`AL-V2-protocolo.md` §5).

import 'dart:math' as math;

import 'fan_point.dart';
import 'rpm_phase.dart';

/// Fan size: defines os limites de RPM da curva.
enum FanSize {
  mm120(diameterMm: 120, maxRpm: 2000, minRpm: 250),
  mm140(diameterMm: 140, maxRpm: 1600, minRpm: 200);

  const FanSize({
    required this.diameterMm,
    required this.maxRpm,
    required this.minRpm,
  });
  final int diameterMm;
  final int maxRpm;
  final int minRpm;
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
