import 'ssd_info.dart';

/// Port: reads SSDs (identification + SMART). Runs in the engine.
abstract interface class SsdReader {
  Future<List<SsdInfo>> read();
}
