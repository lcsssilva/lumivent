import '../domain/sensor_sample.dart';
import '../domain/sensor_history.dart';
import '../domain/ssd_info.dart';

class MonitoringState {
  const MonitoringState({
    this.history = const SensorHistory(),
    this.ssds,
    this.ssdsReadAt,
  });

  final SensorHistory history;

  /// `null` until the first SSD reading.
  final List<SsdInfo>? ssds;
  final DateTime? ssdsReadAt;

  SensorSample? get latest => history.latest;

  MonitoringState copyWith({
    SensorHistory? history,
    List<SsdInfo>? ssds,
    DateTime? ssdsReadAt,
  }) => MonitoringState(
    history: history ?? this.history,
    ssds: ssds ?? this.ssds,
    ssdsReadAt: ssdsReadAt ?? this.ssdsReadAt,
  );
}
