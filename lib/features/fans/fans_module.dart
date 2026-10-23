import 'package:flutter_riverpod/misc.dart' show Override;

import '../../core/persistence/config_store.dart';
import '../devices/devices.dart' show Alv2HubProxy;
import '../monitoring/monitoring.dart' show SensorSample;
import 'application/fans_notifier.dart';
import 'application/fans_engine_module.dart';
import 'domain/fans_config.dart';
import 'domain/fans_repository.dart';
import 'infrastructure/alv2_fan_driver.dart';
import 'infrastructure/json_fans_repository.dart';
import 'infrastructure/metrics_fan_temperatures.dart';

/// Module composition: connects ports to implementations.
abstract final class FansModule {
  static FansRepository repository(ConfigStore store) =>
      JsonFansRepository(store);

  static List<Override> overrides(ConfigStore store) => [
    fansRepositoryProvider.overrideWithValue(repository(store)),
  ];

  /// Engine part. Called inside the isolate. [hub] is shared with monitoring,
  /// which releases it; [latest] returns the latest sensor reading.
  static FansEngineModule engine({
    required Alv2HubProxy hub,
    required SensorSample? Function() latest,
    required FansConfig initial,
  }) => FansEngineModule(
    () => Alv2FanDriver(hub),
    MetricsFanTemperatures(latest),
    initial,
  );
}
