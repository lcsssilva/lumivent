import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/app_strings.dart';
import '../../../preferences/preferences.dart';
import '../../application/monitoring_notifier.dart';
import '../../domain/metrics.dart';
import '../../domain/sensor_history.dart';
import '../../domain/ssd_info.dart';
import '../sensor_format.dart';

/// Readings shown by the monitoring view, in the user's temperature unit.
/// The view has no actions, so this is an immutable presentation model;
/// text that depends on the language takes the catalog of the widget tree.
class MonitoringViewModel {
  const MonitoringViewModel({
    required this.history,
    required this.temperatureUnit,
    this.ssds,
    this.ssdsReadAt,
  });

  final SensorHistory history;
  final TemperatureUnit temperatureUnit;

  /// NVMe drives, `null` until the first SSD reading.
  final List<SsdInfo>? ssds;
  final DateTime? ssdsReadAt;

  /// Latest value of metric [id], `null` without a reading.
  double? now(String id) => history.latest?[id];

  /// Latest temperature of metric [id], formatted.
  String temp(String id) => formatTemp(now(id), temperatureUnit);

  /// A temperature given in °C, formatted (chart labels).
  String tempLabel(double celsius) => formatTemp(celsius, temperatureUnit);

  /// Latest value of metric [id] in [unit], formatted for [strings].
  String metric(String id, MetricUnit unit, AppStrings strings) =>
      formatMetric(now(id), unit, temperatureUnit, strings);
}

final monitoringViewModelProvider = Provider.autoDispose<MonitoringViewModel>((
  ref,
) {
  final monitoring = ref.watch(monitoringProvider);
  return MonitoringViewModel(
    history: monitoring.history,
    temperatureUnit: ref.watch(
      preferencesProvider.select((p) => p.temperatureUnit),
    ),
    ssds: monitoring.ssds,
    ssdsReadAt: monitoring.ssdsReadAt,
  );
});
