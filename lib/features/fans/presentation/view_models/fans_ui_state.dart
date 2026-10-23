import '../../../monitoring/monitoring.dart';
import '../../../preferences/preferences.dart';
import '../../application/fan_group_status.dart';
import '../../application/fan_temp_metric.dart';
import '../../application/fans_status.dart';
import '../../domain/fan_group.dart';
import '../../domain/fan_group_config.dart';
import '../../domain/fans_config.dart';

/// Everything the fans view renders: the configuration, the live readings,
/// and the group the user selected. Derived values are computed from these
/// inputs so the view only formats and lays them out.
class FansUiState {
  const FansUiState({
    required this.config,
    required this.history,
    required this.status,
    required this.temperatureUnit,
    this.selectedGroup,
  });

  /// Samples kept for the live trace drawn over the curve.
  static const traceLength = 60;

  /// Minimum gap (°C) between the raw and the filtered temperature for the
  /// raw reading to be shown next to it.
  static const rawTemperatureGap = .5;

  final FansConfig config;
  final SensorHistory history;

  /// Last fan loop cycle (`null` until the first cycle).
  final FansStatus? status;
  final TemperatureUnit temperatureUnit;

  /// Group chosen by the user; `null` selects [selectedIndex] automatically.
  final int? selectedGroup;

  FansUiState withSelectedGroup(int group) => FansUiState(
    config: config,
    history: history,
    status: status,
    temperatureUnit: temperatureUnit,
    selectedGroup: group,
  );

  /// Whether each hub group has ever reported a positive RPM.
  List<bool> get groupsWithFan => [
    for (var g = 0; g < fanGroupCount; g++)
      history.everPositive(Metrics.alv2Rpm(g)),
  ];

  /// The user's choice, else the first group with a fan, else group 1.
  int get selectedIndex {
    final explicit = selectedGroup;
    if (explicit != null) return explicit;
    final present = groupsWithFan;
    return present.contains(true) ? present.indexOf(true) : 1;
  }

  FanGroupConfig get group => config[selectedIndex];

  FanGroupStatus? get groupStatus =>
      status?.groups.where((g) => g.group == selectedIndex).firstOrNull;

  /// `null` until the engine reports a cycle.
  bool? get hubOk => status?.hubOk;

  SensorSample? get latest => history.latest;

  double? groupRpm(int group) => latest?[Metrics.alv2Rpm(group)];

  double? get rpm => groupRpm(selectedIndex);

  double? get _sourceReading => latest?[fanTempMetric(group.source)];

  /// Temperature driving the curve: the engine's filtered value, else the
  /// current reading of the group's source.
  double? get temperature => groupStatus?.temp ?? _sourceReading;

  /// Unfiltered temperature of the group's source.
  double? get rawTemperature => groupStatus?.rawTemp ?? _sourceReading;

  /// Whether the raw reading differs enough from [temperature] to be shown.
  bool get showsRawTemperature {
    final temp = temperature, raw = rawTemperature;
    return temp != null &&
        raw != null &&
        (raw - temp).abs() >= rawTemperatureGap;
  }

  /// Last [traceLength] readings that have both the temperature and the RPM.
  List<({double temp, double rpm})> get trace {
    final tempMetric = fanTempMetric(group.source);
    final rpmMetric = Metrics.alv2Rpm(selectedIndex);
    final samples = history.samples;
    final recent = samples.length > traceLength
        ? samples.sublist(samples.length - traceLength)
        : samples;
    return [
      for (final s in recent)
        if (s[tempMetric] != null && s[rpmMetric] != null)
          (temp: s[tempMetric]!, rpm: s[rpmMetric]!),
    ];
  }

  /// Current reading of [source], `null` when the sensor is not reporting.
  double? sourceTemperature(FanTempSource source) =>
      latest?[fanTempMetric(source)];

  /// Sources offered for the group: CPU/GPU always; a motherboard sensor only
  /// while it reports a value or when it is the selected source.
  List<FanTempSource> get sourceOptions => [
    for (final s in FanTempSource.values)
      if (!s.isBoard || s == group.source || sourceTemperature(s) != null) s,
  ];
}
