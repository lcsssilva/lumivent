import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/core/platform/hid_api.dart';
import 'package:lumivent/features/devices/domain/device.dart';
import 'package:lumivent/features/devices/domain/device_info.dart';
import 'package:lumivent/features/devices/infrastructure/drivers/alv2/protocol.dart';
import 'package:lumivent/features/devices/infrastructure/hardware_device_detector.dart';

part 'fake_hid_device.dart';
part 'fake_hid_api.dart';

HidDeviceInfo _alv2Node(String path, int interfaceNumber) => HidDeviceInfo(
  path: path,
  vendorId: alv2VendorId,
  productId: alv2ProductId,
  usagePage: 0,
  usage: 0,
  interfaceNumber: interfaceNumber,
);

void main() {
  group('HardwareDeviceDetector AL V2', () {
    late Directory sysfs;
    setUp(() => sysfs = Directory.systemTemp.createTempSync('lumivent-det-'));
    tearDown(() => sysfs.deleteSync(recursive: true));

    DeviceInfo alv2(_FakeHidApi hid) => HardwareDeviceDetector(
      hid: hid,
      sysfsRoot: sysfs.path,
    ).scan().devices.singleWhere((d) => d.id == 'alv2');

    test('only a non-ALV2 interface is reported missing and never opened', () {
      final hid = _FakeHidApi([_alv2Node('/dev/hidraw3', 0)]);
      final info = alv2(hid);
      expect(info.status, DeviceStatus.missing);
      expect(info.issue, DeviceIssue.fanUsbCable);
      expect(hid.opened, isEmpty);
    });

    test('the ALV2 interface is the only node opened', () {
      final hid = _FakeHidApi([
        _alv2Node('/dev/hidraw3', 0),
        _alv2Node('/dev/hidraw4', alv2Interface),
      ]);
      alv2(hid);
      expect(hid.opened, ['/dev/hidraw4']);
    });
  });
}
