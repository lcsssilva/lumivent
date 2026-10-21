import '../../../core/engine/engine_host.dart';
import '../domain/metrics.dart';
import '../domain/ssd.dart';

/// Requests the complete history (the UI calls this when building the page).
class RequestSensorHistory extends EngineCommand {
  const RequestSensorHistory();
}

/// New sensor reading (every 1 s).
class SensorsUpdated extends EngineEvent {
  const SensorsUpdated(this.sample);
  final SensorSample sample;
}

/// Response to [RequestSensorHistory]: up to 5 minutes of readings.
class SensorHistoryReplay extends EngineEvent {
  const SensorHistoryReplay(this.samples);
  final List<SensorSample> samples;
}

class SsdsUpdated extends EngineEvent {
  const SsdsUpdated(this.ssds, this.readAt);
  final List<SsdInfo> ssds;
  final DateTime readAt;
}
