/// Monitoring module: sensors (hwmon, /proc, cpufreq, AL V2 hub) with 5 minutes
/// of history and NVMe SSD health. Public API: other modules import only this file.
library;

export 'application/monitoring_controller.dart'
    show MonitoringController, MonitoringState, monitoringProvider;
export 'application/monitoring_engine_module.dart' show MonitoringEngineModule;
export 'application/monitoring_messages.dart'
    show RequestSensorHistory, SensorHistoryReplay, SensorsUpdated, SsdsUpdated;
export 'domain/metrics.dart'
    show
        MetricDef,
        MetricUnit,
        Metrics,
        SensorHistory,
        SensorSample,
        SensorSource;
export 'domain/ssd.dart'
    show
        NvmeSmartLog,
        SsdErrorKind,
        SsdHealth,
        SsdInfo,
        SsdReader,
        SsdSmartError;
export 'infrastructure/nvme_ssd_reader.dart' show findNvmeSmartHelper;
export 'monitoring_module.dart';
export 'presentation/format.dart' show formatTemp;
export 'presentation/monitoring_page.dart' show MonitoringPage;
export 'presentation/topbar_sensors.dart' show TopbarSensors;
