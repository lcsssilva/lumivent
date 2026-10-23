import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/core/platform/smbus.dart';
import 'package:lumivent/features/devices/infrastructure/drivers/alv2/protocol.dart';
import 'package:lumivent/features/devices/infrastructure/drivers/ite5702/protocol.dart';
import 'package:lumivent/features/devices/infrastructure/drivers/ite5702/ite_forbidden_command.dart';
import 'package:lumivent/features/devices/infrastructure/drivers/kingston_fury/protocol.dart';
import 'package:lumivent/features/devices/infrastructure/process_scan.dart';

List<int> hex(String s) => [
  for (final b in s.split(' ')) int.parse(b, radix: 16),
];

void main() {
  group('AL V2', () {
    test('firmware E0 50 80 C6 04 → 0.4 (AL-V2 §8)', () {
      expect(parseAlv2Firmware(hex('E0 50 80 C6 04')), '0.4');
      expect(parseAlv2Firmware(hex('E0 50 80 C6 13')), '1.3');
    });

    test('non-firmware response returns null', () {
      expect(parseAlv2Firmware(hex('E0 50 00 03 ED')), isNull);
      expect(parseAlv2Firmware(hex('E0 50')), isNull);
    });

    test(
      'RPM F0 00 00 03 ED 04 CE 04 CE → [0, 1005, 1230, 1230] (AL-V2 §8)',
      () {
        expect(parseAlv2Rpm(hex('F0 00 00 03 ED 04 CE 04 CE')), [
          0,
          1005,
          1230,
          1230,
        ]);
        expect(alv2ReadRpm, hex('E0 50 00'));
      },
    );

    test('stale response data or short payload does not become RPM', () {
      expect(parseAlv2Rpm(hex('E0 50 80 C6 04 04 DD 04 DD')), isNull);
      expect(parseAlv2Rpm(hex('F0 00 00 03')), isNull);
    });

    test('hidraw repeats the report ID: the first E0 is removed', () {
      expect(alv2InputPayload(hex('E0 E0 50 80 C6 04')), hex('E0 50 80 C6 04'));
    });
  });

  group('ITE 5702', () {
    // CC 60 table read from this board (ITE §2.3).
    final table = hex(
      'CC 01 00 07 04 00 17 00 '
      '00 00 00 00 49 54 35 37 '
      '30 31 2D 47 49 47 41 42 '
      '59 54 45 20 56 34 2E 30 '
      '2E 32 33 2E 30 00 00 00 '
      '00 01 02 00 02 00 01 00 '
      '02 00 01 00 02 00 01 00 '
      '00 01 01 57 00 00 00 00',
    );

    test('CC 60 returns firmware and description', () {
      final info = parseIteInfo(table)!;
      expect(info.firmware, '4.0.23.0');
      expect(info.description, 'IT5701-GIGABYTE V4.0.23.0');
    });

    test('short or different report response returns null', () {
      expect(parseIteInfo(table.sublist(0, 20)), isNull);
      expect(parseIteInfo([0x10, ...table.skip(1)]), isNull);
    });

    test('CC 5E, CC 47, and CC 48 are blocked; CC 60 passes', () {
      for (final cmd in [0x5E, 0x47, 0x48]) {
        expect(
          () => checkIteCommand([0xCC, cmd, 0x01]),
          throwsA(isA<IteForbiddenCommand>()),
        );
      }
      expect(() => checkIteCommand(iteReadInfo), returnsNormally);
      expect(() => checkIteCommand([0xCC, 0x28, 0xFF]), returnsNormally);
    });
  });

  group('Kingston Fury', () {
    test('0xDD guard: 0x72/0x78 (PWM controller) are blocked', () {
      expect(furyGuardAllows(0x72), isFalse);
      expect(furyGuardAllows(0x78), isFalse);
      expect(furyGuardAllows(0x5A), isTrue);
    });

    test('SPD addresses (0x50–0x57) are always blocked', () {
      for (var a = 0x50; a <= 0x57; a++) {
        expect(
          isForbiddenSmbusAddress(a),
          isTrue,
          reason: '0x${a.toRadixString(16)}',
        );
      }
      expect(isForbiddenSmbusAddress(0x4F), isFalse);
      expect(isForbiddenSmbusAddress(0x58), isFalse);
      expect(furyAddresses.any(isForbiddenSmbusAddress), isFalse);
    });

    test('non-7-bit addresses are rejected before any ioctl', () {
      // A regular file stands in for /dev/i2c-N: the guard must throw before
      // I2C_SLAVE, so no ioctl ever reaches it.
      final dir = Directory.systemTemp.createTempSync('lumivent-smbus-');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/i2c-0')..createSync();
      final bus = SmBus.open(file.path);
      addTearDown(bus.close);
      // 0xB4 is the 8-bit form of 0x5A; it would address another device.
      for (final addr in [-1, 0x80, 0xB4, 0x3FF]) {
        expect(
          () => bus.writeByteData(addr, 0x00, 0x00),
          throwsArgumentError,
          reason: '0x${addr.toRadixString(16)}',
        );
        expect(() => bus.readByteData(addr, 0x00), throwsArgumentError);
        expect(() => bus.writeQuick(addr), throwsArgumentError);
      }
    });
  });

  group('fake sysfs and /proc', () {
    late Directory root;
    setUp(() => root = Directory.systemTemp.createTempSync('lumivent-sys-'));
    tearDown(() => root.deleteSync(recursive: true));

    void write(String path, String content) => (File(
      '${root.path}/$path',
    )..createSync(recursive: true)).writeAsStringSync(content);

    test('PIIX4 bus is found by name, not number', () {
      write('class/i2c-dev/i2c-3/name', 'AMDGPU DM i2c hw bus 0\n');
      write(
        'class/i2c-dev/i2c-10/name',
        'SMBus PIIX4 adapter port 0 at 0b00\n',
      );
      write(
        'class/i2c-dev/i2c-12/name',
        'SMBus PIIX4 adapter port 1 at 0b20\n',
      );
      expect(
        findI2cBusByName(furyBusName, sysfsRoot: root.path),
        '/dev/i2c-10',
      );
      expect(findI2cBusByName('outro', sysfsRoot: root.path), isNull);
    });

    test('competing programs are detected by comm and argv', () {
      write('100/comm', 'openrgb\n');
      write('100/cmdline', '/usr/bin/openrgb\x00--server\x00');
      write('200/comm', 'python3\n');
      write(
        '200/cmdline',
        '/usr/bin/python3\x00/usr/bin/liquidctl\x00status\x00',
      );
      write('300/comm', 'bash\n');
      write('300/cmdline', 'bash\x00');
      write('400/comm', 'openrgb\n'); // the current process is ignored
      write('self/comm', 'x\n');
      expect(findConflictingPrograms(procRoot: root.path, selfPid: 400), [
        'OpenRGB',
        'liquidctl',
      ]);
      expect(findConflictingPrograms(procRoot: root.path, selfPid: 100), [
        'OpenRGB',
        'liquidctl',
      ]);
    });
  });
}
