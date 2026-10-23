part of 'hardware_device_detector_test.dart';

class _FakeHidApi implements HidApi {
  _FakeHidApi(this.devices);
  final List<HidDeviceInfo> devices;
  final opened = <String>[];

  @override
  List<HidDeviceInfo> enumerate({int vendorId = 0, int productId = 0}) => [
    for (final d in devices)
      if (d.vendorId == vendorId && d.productId == productId) d,
  ];

  @override
  HidDevice openPath(String path) {
    opened.add(path);
    return _FakeHidDevice();
  }

  @override
  void dispose() {}
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
