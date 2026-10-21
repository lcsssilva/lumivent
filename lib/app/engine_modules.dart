// Modules that run inside the engine. Executed in the engine isolate.
import '../core/engine/engine_host.dart';
import '../features/devices/devices.dart';
import '../features/fans/fans.dart';
import '../features/lighting/lighting.dart';
import '../features/monitoring/monitoring.dart';

/// Initial state the engine needs from the UI.
class EngineInit {
  const EngineInit({
    required this.lighting,
    required this.lightingFps,
    required this.fans,
  });
  final LightingConfig lighting;

  /// Frame rate of the LED loop (preferences); changes later arrive as a
  /// `SetLightingFps` command.
  final int lightingFps;
  final FansConfig fans;
}

List<EngineModule> buildEngineModules(EngineInit init) {
  // Proxy of the AL V2 hub, which runs in its own isolate (every hidraw write
  // blocks its thread) and is shared by monitoring (RPM reads and release),
  // fans (duty), and lighting (frames). Order matters: the engine stops in
  // reverse order and waits for each module, so lighting stops first (no frame
  // is sent after the hub closes), then fans send their exit duty and wait for the
  // hub to confirm it, and only then monitoring releases the hub.
  final hub = Alv2HubProxy.open();
  final monitoring = MonitoringModule.engine(hub);
  return [
    DevicesEngineModule(HardwareDeviceDetector.open),
    monitoring,
    FansModule.engine(
      hub: hub,
      latest: () => monitoring.latest,
      initial: init.fans,
    ),
    LightingModule.engine(
      hub: hub,
      initial: init.lighting,
      fps: init.lightingFps,
    ),
  ];
}
