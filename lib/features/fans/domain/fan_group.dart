// Fans module domain (pure Dart): configuration for each AL V2 hub group
// and the module ports.

import 'fan_curve.dart';
import 'fan_response.dart';

/// AL V2 hub groups (physical ports).
const fanGroupCount = 4;

/// Temperature followed by the curve: CPU/GPU, or a motherboard sensor
/// (IT8689E/IT8792E, names from protocol notes §2.5).
enum FanTempSource {
  cpuTctl,
  gpuJunction,
  gpuEdge,
  boardSystem1,
  boardSystem2,
  boardPch,
  boardCpuSocket,
  boardVrm,
  boardPciex16,
  boardPciex4;

  bool get isBoard => !const {cpuTctl, gpuJunction, gpuEdge}.contains(this);
}

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

/// Configuration for the 4 hub groups.
class FansConfig {
  FansConfig(List<FanGroupConfig> groups) : groups = List.unmodifiable(groups) {
    assert(groups.length == fanGroupCount);
    assert(groups.indexed.every((e) => e.$2.group == e.$1));
  }

  /// Factory default: Standard based on CPU. On this PC group 1 has 140 mm fans
  /// (AL-V2 §8); the others have 120 mm.
  factory FansConfig.defaults() => FansConfig([
    for (var g = 0; g < fanGroupCount; g++)
      FanGroupConfig(
        group: g,
        name: 'Grupo $g',
        size: g == 1 ? FanSize.mm140 : FanSize.mm120,
      ),
  ]);

  final List<FanGroupConfig> groups;

  FanGroupConfig operator [](int group) => groups[group];

  FansConfig replaced(FanGroupConfig g) =>
      FansConfig([...groups]..[g.group] = g);

  /// "Apply to all groups": copies the curve from [group] to the others.
  FansConfig curveAppliedToAll(int group) {
    final src = groups[group];
    return FansConfig([
      for (final g in groups) g.group == group ? g : g.withCurveOf(src),
    ]);
  }
}

// ── Portas ──────────────────────────────────────────────────────────────────

/// Hub output. Implemented by the devices module AL V2 driver.
abstract interface class FanDriver {
  /// Sends duty (1–100) for [group]. `false` if the hub is inaccessible.
  Future<bool> setDuty(int group, int duty);

  /// Disables motherboard RPM sync for all 4 groups. The app controls the fans;
  /// otherwise (for example, if the vendor software left sync enabled on
  /// Windows), the hub would ignore duty. `false` if inaccessible.
  Future<bool> disableMotherboardSync();
}

/// Temperatures the curve can follow, read by the engine. `null` = no reading.
abstract interface class FanTemperatures {
  double? read(FanTempSource source);
}

/// Persistence for fan configuration.
abstract interface class FansRepository {
  FansConfig load();
  Future<void> save(FansConfig config);
}
