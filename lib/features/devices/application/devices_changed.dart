import '../../../core/engine/engine_event.dart';
import '../domain/device_snapshot.dart';

class DevicesChanged extends EngineEvent {
  const DevicesChanged(this.snapshot);
  final DeviceSnapshot snapshot;
}
