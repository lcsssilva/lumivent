part of 'light_io_worker_test.dart';

class _IoWorkerIteTransport implements IteTransport {
  final sent = <List<int>>[];
  bool closed = false;
  @override
  void sendFeature(List<int> data, int length) => sent.add(List.of(data));
  @override
  Uint8List getFeature(int reportId, int length) => Uint8List(64);
  @override
  void close() => closed = true;
}
