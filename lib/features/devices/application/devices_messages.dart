import '../../../core/engine/engine_host.dart';
import '../domain/device.dart';

/// Performs a full detection now.
class RescanDevices extends EngineCommand {
  const RescanDevices();
}

class DevicesChanged extends EngineEvent {
  const DevicesChanged(this.snapshot);
  final DeviceSnapshot snapshot;
}
