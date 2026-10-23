import 'diagnostic_data.dart';

class MemorySmbusData extends DiagnosticData {
  const MemorySmbusData({this.bus});

  /// SMBus the memory sits on, or null when it was not found.
  final String? bus;
}
