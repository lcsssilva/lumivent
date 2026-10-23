import '../../monitoring/monitoring.dart' show SensorSample;
import '../application/fan_temp_metric.dart';
import '../domain/fan_group.dart';

/// Curve temperatures from the latest monitoring reading.
class MetricsFanTemperatures implements FanTemperatures {
  MetricsFanTemperatures(this._latest);

  /// Latest sensor sample (`null` before the first reading).
  final SensorSample? Function() _latest;

  @override
  double? read(FanTempSource source) =>
      _latest()?.values[fanTempMetric(source)];
}
