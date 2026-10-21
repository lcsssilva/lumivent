// Sensor value formatting in pt-BR (decimal comma, thousands separator).
import '../../preferences/preferences.dart' show TemperatureUnit;
import '../domain/metrics.dart';
import '../domain/ssd.dart';

const dash = '—';

String decimal(double v, int digits) =>
    v.toStringAsFixed(digits).replaceAll('.', ',');

/// Integer with thousands separator: 1820 → "1.820".
String grouped(int v) {
  final s = v.abs().toString();
  final b = StringBuffer(v < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return b.toString();
}

double toUnit(double celsius, TemperatureUnit unit) =>
    unit == TemperatureUnit.fahrenheit ? celsius * 9 / 5 + 32 : celsius;

String formatTemp(double? celsius, TemperatureUnit unit) => celsius == null
    ? dash
    : '${toUnit(celsius, unit).round()} ${unit == TemperatureUnit.fahrenheit ? '°F' : '°C'}';

/// Binary bytes (memory): "21,8 GiB".
String formatGiB(double bytes) => '${decimal(bytes / (1 << 30), 1)} GiB';

/// Decimal bytes (storage, as manufacturers report): "12,4 TB", "820 GB".
String formatStorage(num bytes) {
  if (bytes >= 1e12) {
    return '${decimal(bytes / 1e12, bytes >= 1e14 ? 0 : 1)} TB';
  }
  if (bytes >= 1e9) return '${(bytes / 1e9).round()} GB';
  return '${(bytes / 1e6).round()} MB';
}

String formatMetric(double? v, MetricUnit unit, TemperatureUnit tempUnit) {
  if (v == null) return dash;
  return switch (unit) {
    MetricUnit.celsius => formatTemp(v, tempUnit),
    MetricUnit.percent => '${v.round()} %',
    MetricUnit.megahertz =>
      v >= 1000 ? '${decimal(v / 1000, 2)} GHz' : '${v.round()} MHz',
    MetricUnit.rpm => '${grouped(v.round())} rpm',
    MetricUnit.watts => '${v.round()} W',
    MetricUnit.bytes => formatGiB(v),
  };
}

String healthLabel(SsdHealth h) => switch (h) {
  SsdHealth.good => 'Boa',
  SsdHealth.caution => 'Atenção',
  SsdHealth.bad => 'Ruim',
};
