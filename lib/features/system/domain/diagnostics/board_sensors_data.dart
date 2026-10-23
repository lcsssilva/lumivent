import 'diagnostic_data.dart';

class BoardSensorsData extends DiagnosticData {
  const BoardSensorsData(this.modules);

  /// Super I/O hwmon drivers that are loaded.
  final List<String> modules;
}
