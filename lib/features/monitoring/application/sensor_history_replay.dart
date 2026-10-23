import '../../../core/engine/engine_event.dart';
import '../domain/sensor_sample.dart';
import 'request_sensor_history.dart';

/// Response to [RequestSensorHistory]: up to 5 minutes of readings.
class SensorHistoryReplay extends EngineEvent {
  const SensorHistoryReplay(this.samples);
  final List<SensorSample> samples;
}
