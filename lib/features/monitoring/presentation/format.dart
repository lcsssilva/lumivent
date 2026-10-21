// Sensor value formatting. Separators follow the active UI language.
import '../../../core/i18n/app_strings.dart';
import '../../preferences/preferences.dart' show TemperatureUnit;
import '../domain/metrics.dart';
import '../domain/ssd.dart';

const dash = '—';

double toUnit(double celsius, TemperatureUnit unit) =>
    unit == TemperatureUnit.fahrenheit ? celsius * 9 / 5 + 32 : celsius;

String formatTemp(double? celsius, TemperatureUnit unit) => celsius == null
    ? dash
    : '${toUnit(celsius, unit).round()} ${unit == TemperatureUnit.fahrenheit ? '°F' : '°C'}';

/// Binary bytes (memory): "21.8 GiB" / "21,8 GiB".
String formatGiB(double bytes, AppStrings strings) =>
    '${strings.decimal(bytes / (1 << 30), 1)} GiB';

/// Decimal bytes (storage, as manufacturers report): "12.4 TB", "820 GB".
String formatStorage(num bytes, AppStrings strings) {
  if (bytes >= 1e12) {
    return '${strings.decimal(bytes / 1e12, bytes >= 1e14 ? 0 : 1)} TB';
  }
  if (bytes >= 1e9) return '${(bytes / 1e9).round()} GB';
  return '${(bytes / 1e6).round()} MB';
}

String formatMetric(
  double? v,
  MetricUnit unit,
  TemperatureUnit tempUnit,
  AppStrings strings,
) {
  if (v == null) return dash;
  return switch (unit) {
    MetricUnit.celsius => formatTemp(v, tempUnit),
    MetricUnit.percent => '${v.round()} %',
    MetricUnit.megahertz =>
      v >= 1000 ? '${strings.decimal(v / 1000, 2)} GHz' : '${v.round()} MHz',
    MetricUnit.rpm => '${strings.grouped(v.round())} rpm',
    MetricUnit.watts => '${v.round()} W',
    MetricUnit.bytes => formatGiB(v, strings),
  };
}

String healthLabel(SsdHealth h, AppStrings strings) => switch (h) {
  SsdHealth.good => strings.monitoring.healthGood,
  SsdHealth.caution => strings.monitoring.healthWarning,
  SsdHealth.bad => strings.monitoring.healthBad,
};
