import 'package:lumivent/core/platform/hid_api.dart';
import 'package:lumivent/core/platform/hid_device_info.dart';

import 'fake_hid_device.dart';

class FakeHidApi implements HidApi {
  FakeHidApi(this.devices);
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
    return FakeHidDevice();
  }

  @override
  void dispose() {}
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
