import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/devices/infrastructure/drivers/alv2/hub.dart';
import 'package:lumivent/features/devices/infrastructure/drivers/alv2/protocol.dart';

List<int> hex(String s) => [
  for (final b in s.split(' ')) int.parse(b, radix: 16),
];

void main() {
  group('AL V2 control packets', () {
    test('duty: E0 (20|g) 00 duty', () {
      expect(alv2DutyPacket(1, 100), hex('E0 21 00 64'));
      expect(alv2DutyPacket(0, 50), hex('E0 20 00 32'));
      expect(alv2DutyPacket(3, 1), hex('E0 23 00 01'));
    });

    test('duty is clamped to 1–100', () {
      expect(alv2DutyPacket(2, 0)[3], 1);
      expect(alv2DutyPacket(2, -5)[3], 1);
      expect(alv2DutyPacket(2, 250)[3], 100);
    });

    test('RPM sync: E0 10 62 m 00 00, one packet per group', () {
      // Only group 2 is enabled.
      final sync = [false, false, true, false];
      expect(alv2MotherboardSyncPackets(sync), [
        hex('E0 10 62 10 00 00'),
        hex('E0 10 62 20 00 00'),
        hex('E0 10 62 44 00 00'),
        hex('E0 10 62 80 00 00'),
      ]);
      expect(
        alv2MotherboardSyncPacket(0, List.filled(4, true)),
        hex('E0 10 62 11 00 00'),
      );
      expect(
        alv2MotherboardSyncPacket(3, List.filled(4, true)),
        hex('E0 10 62 88 00 00'),
      );
    });
  });

  test('hub without hidapi does not access anything or crash', () {
    final hub = Alv2Hub(null);
    expect(hub.readRpm(), isNull);
    expect(hub.setDuty(0, 50), isFalse);
    expect(hub.setDuty(9, 50), isFalse);
    expect(hub.setMotherboardSync(List.filled(4, false)), isFalse);
    expect(hub.setMotherboardSync([true]), isFalse);
    hub.dispose();
  });
}
