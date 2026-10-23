part of 'monitoring_engine_test.dart';

class _RpmTransport implements Alv2Transport {
  final log = <String>[];
  Completer<void>? gate;

  @override
  void sendFeature(List<int> data, int length) => log.add('feature');
  @override
  void write(List<int> data, int length) {}
  @override
  Uint8List getInput(int reportId, int length) =>
      Uint8List(length)
        ..setRange(0, 10, [0xE0, 0xF0, 0, 0, 0x03, 0xED, 0x04, 0xCE, 4, 0xCE]);
  @override
  void close() => log.add('close');
}
