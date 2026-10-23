import '../../../../core/engine/engine_event.dart';
import '../../domain/sensor_sample.dart';

/// New sensor reading (every 1 s).
class SensorsUpdated extends EngineEvent {
  const SensorsUpdated(this.sample);
  final SensorSample sample;
}
