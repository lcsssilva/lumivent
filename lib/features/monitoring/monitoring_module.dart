import '../devices/devices.dart' show Alv2HubProxy;
import 'application/monitoring_engine_module.dart';
import 'infrastructure/alv2_rpm_source.dart';
import 'infrastructure/nvme_ssd_reader.dart';
import 'infrastructure/sysfs_sensor_source.dart';

/// Module composition: connects ports to implementations.
abstract final class MonitoringModule {
  /// Engine part, with the real sources. Called inside the isolate. The [hub]
  /// is released by `Alv2RpmSource` when the engine stops.
  static MonitoringEngineModule engine(Alv2HubProxy hub) =>
      MonitoringEngineModule(
        () => [SysfsSensorSource(), Alv2RpmSource(hub)],
        NvmeSsdReader.new,
      );
}
