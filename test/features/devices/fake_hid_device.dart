part of 'hardware_device_detector_test.dart';

class _FakeHidDevice implements HidDevice {
  @override
  void sendFeature(List<int> data, int length) {}
  @override
  Uint8List getInput(int reportId, int length) => Uint8List(length);
  @override
  void close() {}
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
