import 'dart:typed_data';

/// Minimal ITE transport (feature reports); tests use a fake.
abstract interface class IteTransport {
  void sendFeature(List<int> data, int length);
  Uint8List getFeature(int reportId, int length);
  void close();
}
