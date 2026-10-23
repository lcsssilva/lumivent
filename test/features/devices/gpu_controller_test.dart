import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/core/platform/raw_i2c_bus.dart';
import 'package:lumivent/core/platform/raw_i2c_exception.dart';
import 'package:lumivent/features/devices/devices.dart';

import 'fake_gpu_transport.dart';

Uint8List firmware([int family = 1, int major = 1, int minor = 2]) =>
    Uint8List.fromList([0x01, family, major, minor]);

Uint8List ssid(int value) =>
    Uint8List.fromList([0x01, 0x01, value >> 8, value & 0xFF]);

void main() {
  group('protocol guards', () {
    Uint8List identification([int command = 0x10]) => buildGpuCommand(command);

    Uint8List effect({
      GpuEffectCode code = GpuEffectCode.staticColor,
      int speed = 0,
      int brightness = 0,
      int zone = 0,
      int colors = 0,
    }) {
      final packet = buildGpuEffectPacket(
        effect: code,
        speed: speed,
        brightness: brightness,
        color: const GpuRgb(1, 2, 3),
      );
      packet[9] = zone;
      if (colors != 0) packet[10] = colors;
      return packet;
    }

    test('accepts a 64-byte identification packet', () {
      checkGpuPacket(
        identification(),
        address: gpuI2cAddress,
        busValidated: true,
        ssidValidated: false,
      );
    });

    test('rejects an unvalidated bus before touching the packet', () {
      expect(
        () => checkGpuPacket(
          Uint8List(1),
          address: 0x50,
          busValidated: false,
          ssidValidated: false,
        ),
        throwsA(
          isA<GpuGuardException>().having(
            (e) => e.message,
            'message',
            contains('unvalidated bus'),
          ),
        ),
      );
    });

    test('rejects every address except 0x75', () {
      for (final address in [0x74, 0x76, 0x50]) {
        expect(
          () => checkGpuPacket(
            identification(),
            address: address,
            busValidated: true,
            ssidValidated: false,
          ),
          throwsA(isA<GpuGuardException>()),
          reason: '0x${address.toRadixString(16)}',
        );
      }
    });

    test('rejects sizes other than 64 bytes', () {
      for (final length in [0, 1, 63, 65]) {
        expect(
          () => checkGpuPacket(
            Uint8List(length),
            address: gpuI2cAddress,
            busValidated: true,
            ssidValidated: false,
          ),
          throwsA(isA<GpuGuardException>()),
          reason: '$length B',
        );
      }
    });

    test('blocks 0x13, 0x16, 0x17 and 0x18', () {
      for (final command in [0x13, 0x16, 0x17, 0x18]) {
        expect(
          () => checkGpuPacket(
            identification(command),
            address: gpuI2cAddress,
            busValidated: true,
            ssidValidated: true,
          ),
          throwsA(
            isA<GpuGuardException>().having(
              (e) => e.message,
              'message',
              contains('blocked for safety'),
            ),
          ),
          reason: '0x${command.toRadixString(16)}',
        );
      }
    });

    test('only 0x10, 0x11 and 0x12 are allowed', () {
      for (final command in [0x00, 0x0F, 0x14, 0x15, 0x19, 0xFF]) {
        expect(
          () => checkGpuPacket(
            identification(command),
            address: gpuI2cAddress,
            busValidated: true,
            ssidValidated: false,
          ),
          throwsA(
            isA<GpuGuardException>().having(
              (e) => e.message,
              'message',
              contains('not allowed'),
            ),
          ),
          reason: '0x${command.toRadixString(16)}',
        );
      }
    });

    test('requires byte 1 = 0x01 and zero padding on identification', () {
      final wrong = identification()..[1] = 0x02;
      expect(
        () => checkGpuPacket(
          wrong,
          address: gpuI2cAddress,
          busValidated: true,
          ssidValidated: false,
        ),
        throwsA(isA<GpuGuardException>()),
      );
      final garbage = identification()..[30] = 1;
      expect(
        () => checkGpuPacket(
          garbage,
          address: gpuI2cAddress,
          busValidated: true,
          ssidValidated: false,
        ),
        throwsA(isA<GpuGuardException>()),
      );
    });

    test('refuses any 0x12 before the SSID is validated', () {
      expect(
        () => checkGpuPacket(
          effect(),
          address: gpuI2cAddress,
          busValidated: true,
          ssidValidated: false,
        ),
        throwsA(
          isA<GpuGuardException>().having(
            (e) => e.message,
            'message',
            contains('SSID 0x2429'),
          ),
        ),
      );
    });

    test('validates effect, speed, brightness and zone', () {
      void ok(Uint8List p) => checkGpuPacket(
        p,
        address: gpuI2cAddress,
        busValidated: true,
        ssidValidated: true,
      );
      void bad(Uint8List p) =>
          expect(() => ok(p), throwsA(isA<GpuGuardException>()));

      ok(effect());
      bad(effect(code: GpuEffectCode.values.last)..[2] = 0x7F);
      bad(effect()..[3] = 11);
      bad(effect()..[4] = 11);
      bad(effect(zone: 1));
    });

    test('validates the single-color layout', () {
      final p = effect()..[10] = 1;
      expect(
        () => checkGpuPacket(
          p,
          address: gpuI2cAddress,
          busValidated: true,
          ssidValidated: true,
        ),
        throwsA(isA<GpuGuardException>()),
      );
      final trailing = effect()..[20] = 1;
      expect(
        () => checkGpuPacket(
          trailing,
          address: gpuI2cAddress,
          busValidated: true,
          ssidValidated: true,
        ),
        throwsA(isA<GpuGuardException>()),
      );
    });

    test('ColorShift requires eight colors and no trailing bytes', () {
      final packet = buildGpuEffectPacket(
        effect: GpuEffectCode.colorShift,
        speed: 2,
        brightness: 3,
        color: const GpuRgb(1, 2, 3),
        colors: [for (var i = 0; i < 8; i++) GpuRgb(i, i, i)],
      );
      expect(packet[10], 8);
      expect(packet[11], 0);
      expect(packet[34], 7);
      checkGpuPacket(
        packet,
        address: gpuI2cAddress,
        busValidated: true,
        ssidValidated: true,
      );
      expect(
        () => checkGpuPacket(
          packet..[10] = 7,
          address: gpuI2cAddress,
          busValidated: true,
          ssidValidated: true,
        ),
        throwsA(isA<GpuGuardException>()),
      );
      expect(
        () => checkGpuPacket(
          packet
            ..[10] = 8
            ..[40] = 1,
          address: gpuI2cAddress,
          busValidated: true,
          ssidValidated: true,
        ),
        throwsA(isA<GpuGuardException>()),
      );
    });
  });

  group('protocol packets', () {
    test('effect map and names match the firmware table', () {
      expect(GpuEffectCode.byCode(0x00), GpuEffectCode.off);
      expect(GpuEffectCode.byCode(0x0C), GpuEffectCode.claws);
      expect(GpuEffectCode.byStyle(11), GpuEffectCode.tricolor);
      expect(GpuEffectCode.byName('doubleFlash'), GpuEffectCode.doubleFlash);
      expect(GpuEffectCode.byName('nope'), isNull);
      expect(GpuEffectCode.colorShift.colors, 8);
      expect(GpuEffectCode.staticColor.colors, 0);
    });

    test('builds a Static packet with color and clamped levels', () {
      final p = buildGpuEffectPacket(
        effect: GpuEffectCode.staticColor,
        speed: 99,
        brightness: -4,
        color: const GpuRgb(9, 8, 7),
      );
      expect(p.length, 64);
      expect(p.sublist(0, 9), [0x12, 0x01, 0x01, 10, 0, 9, 8, 7, 0]);
      expect(p.sublist(9), everyElement(0));
    });

    test('Off forces speed, brightness and color to zero', () {
      final p = buildGpuEffectPacket(
        effect: GpuEffectCode.off,
        speed: 9,
        brightness: 9,
        color: const GpuRgb(255, 255, 255),
      );
      expect(p.sublist(0, 10), [0x12, 0x01, 0x00, 0, 0, 0, 0, 0, 0, 0]);
    });

    test('ColorShift fills missing palette entries with black', () {
      final p = buildGpuEffectPacket(
        effect: GpuEffectCode.colorShift,
        speed: 1,
        brightness: 2,
        color: GpuRgb.black,
        colors: const [GpuRgb(1, 2, 3)],
      );
      expect(p[10], 8);
      expect(p.sublist(11, 14), [1, 2, 3]);
      expect(p.sublist(14, 35), everyElement(0));
    });

    test('parses firmware and SSID answers', () {
      expect(parseGpuFirmware(firmware()), (version: '1.2', is4N: false));
      expect(parseGpuFirmware(firmware(2, 3, 4)), (version: '3.4', is4N: true));
      expect(parseGpuFirmware(Uint8List.fromList([0, 0, 0, 0])), isNull);
      expect(parseGpuFirmware(Uint8List(3)), isNull);
      expect(parseGpuSsid(ssid(0x2429)), 0x2429);
      expect(parseGpuSsid(Uint8List.fromList([1, 9, 0x24, 0x29])), isNull);
      expect(parseGpuSsid(Uint8List(3)), isNull);
      // Byte 0 other than 0x01/0x02 is not the controller.
      expect(parseGpuSsid(Uint8List.fromList([0, 1, 0x24, 0x29])), isNull);
      expect(parseGpuSsid(Uint8List.fromList([2, 1, 0x24, 0x29])), 0x2429);
    });
  });

  group('raw I2C address guard', () {
    test('never allows SPD/EEPROM addresses', () {
      for (var a = 0x50; a <= 0x57; a++) {
        expect(isForbiddenI2cAddress(a), isTrue, reason: '0x$a');
      }
      expect(isForbiddenI2cAddress(0x4F), isFalse);
      expect(isForbiddenI2cAddress(0x58), isFalse);
      expect(
        () => RawI2cBus.open('/dev/null', address: 0x50),
        throwsArgumentError,
      );
      expect(
        () => RawI2cBus.open('/dev/null', address: 0x80),
        throwsArgumentError,
      );
    });

    test('exclusive locks the adapter against another handle', () {
      // A regular file stands in for /dev/i2c-N: flock does not care.
      final dir = Directory.systemTemp.createTempSync('lumivent-i2c-lock-');
      addTearDown(() => dir.deleteSync(recursive: true));
      final path = '${dir.path}/i2c-test';
      File(path).writeAsBytesSync([]);
      final probe = RawI2cBus.open(path, address: gpuI2cAddress);
      final worker = RawI2cBus.open(path, address: gpuI2cAddress);
      addTearDown(probe.close);
      addTearDown(worker.close);

      probe.exclusive(() {
        expect(
          () => worker.exclusive(() {}),
          throwsA(isA<RawI2cException>().having((e) => e.errno, 'errno', 11)),
        );
      });
      // Released: the other handle gets it at once.
      expect(worker.exclusive(() => 42), 42);
    });
  });

  group('GpuController', () {
    late FakeGpuTransport transport;
    late DateTime now;
    late List<Duration> sleeps;

    GpuController make() => GpuController(
      transport,
      busPath: '/dev/i2c-test',
      now: () => now,
      sleep: (d) {
        sleeps.add(d);
        now = now.add(d);
      },
    );

    setUp(() {
      transport = FakeGpuTransport();
      now = DateTime(2026, 10, 20);
      sleeps = [];
    });

    test('opens only the OEM adapter by name', () {
      final root = Directory.systemTemp.createTempSync('lumivent-gpu-sysfs-');
      addTearDown(() => root.deleteSync(recursive: true));
      Directory('${root.path}/class/i2c-dev').createSync(recursive: true);
      expect(
        () => GpuController.open(sysfsRoot: root.path),
        throwsA(
          isA<GpuException>().having(
            (e) => e.message,
            'message',
            contains(gpuI2cBusName),
          ),
        ),
      );
    });

    test('accepts the answers read from the real board', () {
      // Bytes read from /dev/i2c-7 on 2026-10-20 (RX 9060 XT GAMING OC 8G).
      transport.reads.addAll([
        Uint8List.fromList([0x01, 0x01, 0x01, 0x01]),
        Uint8List.fromList([0x02, 0x01, 0x24, 0x29]),
      ]);
      final c = make();
      expect(c.init(), isTrue);
      expect(c.firmware, '1.1');
      expect(c.ssid, gpuSsid);
      expect(c.disabledReason, isNull);
    });

    test('init reads firmware and the validated SSID', () {
      transport.reads.addAll([firmware(), ssid(gpuSsid)]);
      final c = make();
      expect(c.init(), isTrue);
      expect(c.firmware, '1.2');
      expect(c.ssid, gpuSsid);
      expect(c.is4N, isFalse);
      expect(c.disabledReason, isNull);
      expect(transport.writes.map((p) => p[0]), [0x10, 0x11]);
      expect(transport.writes.every((p) => p.length == 64), isTrue);
      // Only the pause between the two reads blocks; the settle after the
      // SSID is left to the next command (the probe closes the bus instead).
      expect(sleeps, [gpuReadSettle]);
    });

    test('each command and its answer run under one lock hold', () {
      transport.reads.addAll([firmware(), ssid(gpuSsid)]);
      final c = make();
      expect(c.init(), isTrue);
      expect(
        c.sendEffect(
          effect: GpuEffectCode.staticColor,
          speed: 0,
          brightness: 10,
          color: const GpuRgb(1, 2, 3),
        ),
        isTrue,
      );
      expect(transport.unlocked, 0);
      expect(transport.holds, [
        ['w10', 'r'],
        ['w11', 'r'],
        ['w12'],
      ]);
    });

    test('the first effect waits for the settle after the SSID read', () {
      transport.reads.addAll([firmware(), ssid(gpuSsid)]);
      final c = make();
      expect(c.init(), isTrue);
      now = now.add(const Duration(milliseconds: 50));
      expect(
        c.sendEffect(
          effect: GpuEffectCode.staticColor,
          speed: 0,
          brightness: 10,
          color: const GpuRgb(1, 2, 3),
        ),
        isTrue,
      );
      expect(sleeps, [
        gpuReadSettle,
        gpuReadSettle - const Duration(milliseconds: 50),
        gpuEffectGap,
      ]);
    });

    test('a failed identification read blocks every effect', () {
      transport.failRead = true;
      final c = make();
      expect(c.init(), isFalse);
      expect(c.disabledReason, contains('read of command 0x10'));
      expect(c.disabledReason, contains('errno 5'));
      expect(transport.writes, hasLength(1));
      expect(
        c.sendEffect(
          effect: GpuEffectCode.staticColor,
          speed: 0,
          brightness: 10,
          color: const GpuRgb(1, 2, 3),
        ),
        isFalse,
      );
      expect(transport.writes, hasLength(1));
    });

    test('an SSID other than 0x2429 is refused', () {
      transport.reads.addAll([firmware(), ssid(0x1458)]);
      final c = make();
      expect(c.init(), isFalse);
      expect(c.disabledReason, contains('0x1458'));
      expect(c.ssid, 0x1458);
      expect(
        c.sendEffect(
          effect: GpuEffectCode.off,
          speed: 0,
          brightness: 0,
          color: GpuRgb.black,
        ),
        isFalse,
      );
      expect(transport.writes, hasLength(2));
    });

    test('sends a 0x12 only after init and waits 120 ms', () {
      final c = make();
      expect(
        c.sendEffect(
          effect: GpuEffectCode.staticColor,
          speed: 1,
          brightness: 2,
          color: const GpuRgb(3, 4, 5),
        ),
        isFalse,
      );
      expect(transport.writes, isEmpty);
      expect(c.disabledReason, contains('SSID 0x2429'));

      transport.reads.addAll([firmware(), ssid(gpuSsid)]);
      expect(c.init(), isTrue);
      expect(
        c.sendEffect(
          effect: GpuEffectCode.staticColor,
          speed: 1,
          brightness: 2,
          color: const GpuRgb(3, 4, 5),
        ),
        isTrue,
      );
      expect(transport.writes.last.sublist(0, 8), [
        0x12,
        0x01,
        0x01,
        1,
        2,
        3,
        4,
        5,
      ]);
      expect(sleeps.last, gpuEffectGap);
    });

    test('turnOff initializes the identity before the 0x00 effect', () {
      transport.reads.addAll([firmware(), ssid(gpuSsid)]);
      final c = make();
      expect(c.turnOff(), isTrue);
      expect(transport.writes.map((p) => p[0]), [0x10, 0x11, 0x12]);
      expect(transport.writes.last[2], 0x00);
      expect(transport.writes.last[4], 0);
      expect(sleeps.last, gpuEffectGap);
    });

    test('turnOff sends nothing when the identity read fails', () {
      transport.failRead = true;
      final c = make();
      expect(c.turnOff(), isFalse);
      expect(transport.writes.map((p) => p[0]), [0x10]);
      expect(c.disabledReason, contains('read of command 0x10'));
    });

    test('invalidate forces a new identification', () {
      transport.reads.addAll([
        firmware(),
        ssid(gpuSsid),
        firmware(),
        ssid(gpuSsid),
      ]);
      final c = make();
      expect(c.init(), isTrue);
      c.invalidate();
      expect(
        c.sendEffect(
          effect: GpuEffectCode.off,
          speed: 0,
          brightness: 0,
          color: GpuRgb.black,
        ),
        isFalse,
      );
      expect(transport.readCalls, 2);
      expect(c.init(), isTrue);
      expect(transport.readCalls, 4);
    });

    test('close releases the transport and refuses further work', () {
      final c = make();
      c.close();
      expect(transport.closed, isTrue);
      expect(c.init(), isFalse);
      expect(c.disabledReason, contains('closed'));
    });
  });
}
