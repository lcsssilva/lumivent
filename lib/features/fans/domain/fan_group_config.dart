import 'fan_curve.dart';
import 'fan_point.dart';
import 'fan_presets.dart';
import 'rpm_phase.dart';
import 'fan_response.dart';
import 'fan_group.dart';

/// Group configuration (hub port, up to 6 fans in series).
class FanGroupConfig {
  const FanGroupConfig({
    required this.group,
    required this.name,
    this.size = FanSize.mm120,
    this.preset = FanPreset.standard,
    this.customPoints = FanPresets.standard,
    this.userPoints = const {},
    this.fixedPercent = FanPresets.defaultFixedPercent,
    this.startStop = false,
    this.source = FanTempSource.cpuTctl,
    this.response = FanResponse.normal,
  });

  /// Group index in the hub, 0–3.
  final int group;
  final String name;
  final FanSize size;
  final FanPreset preset;

  /// Points for preset [FanPreset.custom].
  final List<FanPoint> customPoints;

  /// Saved points for UserDefine 1–4 (missing means factory points).
  final Map<FanPreset, List<FanPoint>> userPoints;

  /// Fixed mode speed, in %.
  final double fixedPercent;

  /// Stop the fan below the first point (duty 1).
  final bool startStop;
  final FanTempSource source;

  /// How quickly the fan follows temperature (averaging and ramping).
  final FanResponse response;

  /// Editable points for the active curve (one point at 50 °C in Fixed mode).
  List<FanPoint> get points => switch (preset) {
    FanPreset.custom => customPoints,
    FanPreset.fixed => [FanPoint(50, fixedPercent)],
    final p when p.isUser => userPoints[p] ?? FanPresets.defaults(p),
    final p => FanPresets.defaults(p),
  };

  /// RPM phases interpolated by the engine loop.
  List<RpmPhase> get phases => preset == FanPreset.fixed
      ? fixedRpmPhases(fixedPercent, size)
      : toRpmPhases(points, size, startStop: startStop);

  int targetRpm(double temp) => calculateSpeed(phases, temp);
  int duty(double temp) => dutyFor(targetRpm(temp), size);

  /// Replaces active curve points. A factory preset becomes [FanPreset.custom];
  /// UserDefine points are saved under that preset; Fixed mode only uses the
  /// first point percentage. Limited to [FanPresets.maxPoints].
  FanGroupConfig withPoints(List<FanPoint> points) {
    final pts = ([...points]..sort((a, b) => a.temp.compareTo(b.temp)))
        .take(FanPresets.maxPoints)
        .toList();
    if (preset == FanPreset.fixed) {
      return pts.isEmpty ? this : copyWith(fixedPercent: pts.first.percent);
    }
    if (preset.isUser) {
      return copyWith(userPoints: {...userPoints, preset: pts});
    }
    return copyWith(preset: FanPreset.custom, customPoints: pts);
  }

  /// Duty left on the hub when the app exits (the hub cannot run a curve by
  /// itself): this group's own curve at [temp], ignoring start/stop so the fan
  /// never stays stopped without the app. Without a temperature, uses Standard
  /// at 70 °C.
  int exitDuty(double? temp) {
    final curve = temp == null
        ? toRpmPhases(FanPresets.standard, size, startStop: false)
        : preset == FanPreset.fixed
        ? phases
        : toRpmPhases(points, size, startStop: false);
    return dutyFor(calculateSpeed(curve, temp ?? 70), size);
  }

  /// Copies the curve (preset, points, start/stop, source, and response) from
  /// [other], keeping group, name, and size.
  FanGroupConfig withCurveOf(FanGroupConfig other) => copyWith(
    preset: other.preset,
    customPoints: other.customPoints,
    userPoints: other.userPoints,
    fixedPercent: other.fixedPercent,
    startStop: other.startStop,
    source: other.source,
    response: other.response,
  );

  FanGroupConfig copyWith({
    String? name,
    FanSize? size,
    FanPreset? preset,
    List<FanPoint>? customPoints,
    Map<FanPreset, List<FanPoint>>? userPoints,
    double? fixedPercent,
    bool? startStop,
    FanTempSource? source,
    FanResponse? response,
  }) => FanGroupConfig(
    group: group,
    name: name ?? this.name,
    size: size ?? this.size,
    preset: preset ?? this.preset,
    customPoints: customPoints ?? this.customPoints,
    userPoints: userPoints ?? this.userPoints,
    fixedPercent: fixedPercent ?? this.fixedPercent,
    startStop: startStop ?? this.startStop,
    source: source ?? this.source,
    response: response ?? this.response,
  );
}
