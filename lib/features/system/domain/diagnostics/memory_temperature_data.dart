import 'diagnostic_data.dart';

class MemoryTemperatureData extends DiagnosticData {
  const MemoryTemperatureData({this.driver});

  /// hwmon driver reporting memory temperature, or null when absent.
  final String? driver;
}
