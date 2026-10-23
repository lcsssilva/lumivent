part of 'lighting_test.dart';

class _LightingHubTransport implements Alv2Transport {
  final writes = <List<int>>[];

  /// Report length passed to `write` / `sendFeature`, parallel to [writes].
  final lengths = <int>[];
  bool failNext = false;
  void _log(List<int> data, int length) {
    if (failNext) {
      failNext = false;
      throw HidException('hub failure');
    }
    writes.add(List.of(data));
    lengths.add(length);
  }

  @override
  void sendFeature(List<int> data, int length) => _log(data, length);
  @override
  void write(List<int> data, int length) => _log(data, length);
  @override
  Uint8List getInput(int reportId, int length) => Uint8List(length);
  @override
  void close() {}
}
