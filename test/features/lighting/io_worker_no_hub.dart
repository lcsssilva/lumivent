part of 'light_io_worker_test.dart';

class _IoWorkerNoHub implements Alv2Transport {
  @override
  void sendFeature(List<int> data, int length) {}
  @override
  void write(List<int> data, int length) {}
  @override
  Uint8List getInput(int reportId, int length) => Uint8List(length);
  @override
  void close() {}
}
