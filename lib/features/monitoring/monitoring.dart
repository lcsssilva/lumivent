/// Monitoring module: sensors (hwmon, /proc, cpufreq, AL V2 hub) with 5 minutes
/// of history and NVMe SSD health. Public API: other modules import only this file.
library;

export 'application/monitoring_notifier.dart'
    show MonitoringNotifier, monitoringProvider;
export 'application/monitoring_state.dart' show MonitoringState;
export 'application/monitoring_engine_module.dart' show MonitoringEngineModule;
export 'application/messages/request_sensor_history.dart'
    show RequestSensorHistory;
export 'application/messages/sensor_history_replay.dart'
    show SensorHistoryReplay;
export 'application/messages/sensors_updated.dart' show SensorsUpdated;
export 'application/messages/ssds_updated.dart' show SsdsUpdated;
export 'domain/metric_def.dart' show MetricDef;
export 'domain/metrics.dart' show MetricUnit, Metrics;
export 'domain/sensor_history.dart' show SensorHistory;
export 'domain/sensor_sample.dart' show SensorSample;
export 'domain/sensor_source.dart' show SensorSource;
export 'domain/nvme_smart_log.dart' show NvmeSmartLog;
export 'domain/ssd.dart' show SsdErrorKind, SsdHealth;
export 'domain/ssd_info.dart' show SsdInfo;
export 'domain/ssd_reader.dart' show SsdReader;
export 'domain/ssd_smart_error.dart' show SsdSmartError;
export 'infrastructure/nvme_ssd_reader.dart' show findNvmeSmartHelper;
export 'monitoring_module.dart';
export 'presentation/sensor_format.dart' show formatTemp;
export 'presentation/views/monitoring_view.dart' show MonitoringView;
export 'presentation/widgets/topbar_sensors.dart' show TopbarSensors;
