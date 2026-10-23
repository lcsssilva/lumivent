import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/devices/infrastructure/drivers/ite5702/ite_controller.dart';
import 'package:lumivent/features/devices/infrastructure/drivers/ite5702/ite_hardware_effect.dart';
import 'package:lumivent/features/devices/infrastructure/drivers/ite5702/protocol.dart';
import 'package:lumivent/features/devices/infrastructure/drivers/ite5702/ite_forbidden_command.dart';
import 'package:lumivent/features/devices/infrastructure/drivers/ite5702/ite_color_order.dart';

import 'fake_ite.dart';

List<int> hex(String s) => [
  for (final b in s.split(' ')) int.parse(b, radix: 16),
];

/// `CC 60` response measured (ITE §1.1 / §2.3), 64 bytes.
Uint8List infoTable() {
  final t = Uint8List(64);
  t.setRange(0, 8, hex('CC 01 00 07 04 00 17 00'));
  t.setRange(12, 37, 'IT5701-GIGABYTE V4.0.23.0'.codeUnits);
  t.setRange(
    0x28,
    0x3C,
    hex('00 01 02 00 02 00 01 00 02 00 01 00 02 00 01 00 00 01 01 57'),
  );
  return t;
}

List<int> head(List<int> p, int n) => p.sublist(0, n);

void main() {
  group('packets', () {
    test('D_LED1 stream: 47 LEDs in GRB → 57/57/27 B at offsets 0/57/114', () {
      final rgb = [
        for (var i = 0; i < 47; i++) ...[1, 2, 3],
      ];
      final p = iteStreamPackets(rgb);
      expect(p.length, 3);
      expect(head(p[0], 5), hex('CC 58 00 00 39'));
      expect(head(p[1], 5), hex('CC 58 39 00 39'));
      expect(head(p[2], 5), hex('CC 58 72 00 1B'));
      expect(p.map((e) => e.length - 5), [57, 57, 27]);
      expect(p[0].sublist(5, 8), [2, 1, 3]); // G R B
    });

    test('CC 34: 47 LEDs → 01 and the other codes', () {
      expect(iteLedCountPacket(47), hex('CC 34 01'));
      expect(
        [
          for (final n in [32, 33, 64, 65, 256, 257, 512, 513, 1024])
            iteLedCountEnum(n),
        ],
        [0, 1, 1, 2, 2, 3, 3, 4, 4],
      );
    });

    test('direct mode: bit 0 only', () {
      expect(iteDirectModePacket(1), hex('CC 32 01'));
      expect(() => iteDirectModePacket(3), throwsA(isA<IteForbiddenCommand>()));
      expect(() => iteDirectModePacket(2), throwsA(isA<IteForbiddenCommand>()));
    });

    test('protocol guards reject out-of-range values', () {
      // Bit 1 is caught by the forbidden-command guard; bit 2 reaches the
      // ArgumentError.
      expect(() => iteDirectModePacket(0x04), throwsArgumentError);
      expect(() => iteLedCountEnum(1025), throwsArgumentError);
      // 0x59 is forbidden; another header fails the explicit check.
      expect(
        () => iteStreamPacket(0x59, 0, [1, 2, 3]),
        throwsA(isA<IteForbiddenCommand>()),
      );
      expect(() => iteStreamPacket(0x5A, 0, [1, 2, 3]), throwsArgumentError);
      expect(
        () => iteStreamPacket(iteDLed1Header, 0, const []),
        throwsArgumentError,
      );
      expect(
        () => iteStreamPacket(iteDLed1Header, 0, List.filled(58, 0)),
        throwsArgumentError,
      );
      expect(() => iteStreamPackets(const []), throwsArgumentError);
      expect(() => iteStreamPackets(const [1, 2]), throwsArgumentError);
      expect(() => iteZoneStaticPacket(0x1F, 0, 0, 0), throwsArgumentError);
      expect(() => iteZoneStaticPacket(0x27, 0, 0, 0), throwsArgumentError);
    });

    test('forbidden commands and value objects', () {
      expect(
        () => checkIteCommand(hex('CC 5E')),
        throwsA(isA<IteForbiddenCommand>()),
      );
      expect(IteForbiddenCommand(0x59).toString(), contains('CC 59'));
      const order = IteColorOrder(0, 1, 2);
      expect(order, const IteColorOrder(0, 1, 2));
      expect(order.hashCode, const IteColorOrder(0, 1, 2).hashCode);
      expect(order.toString(), contains('B@0'));
    });

    test('zone 0x20 in BGR: RGB (0,0,255) comes out as FF 00 00', () {
      final p = iteZoneStaticPacket(0x20, 0, 0, 255);
      expect(p.length, 0x11);
      expect(head(p, 5), hex('CC 20 01 00 00'));
      expect(p.sublist(0x0B, 0x11), hex('01 5A 00 FF 00 00'));
      expect(iteZoneStaticPacket(0x23, 0, 255, 0)[2], 0x08);
      expect(iteApplyPacket(), hex('CC 28 FF'));
    });

    test('DataFormat_8297 Static', () {
      final p = const IteHardwareEffect(
        IteHardwareMode.staticColor,
        color: (0x11, 0x22, 0x33),
        speed: 3,
        brightness: 9,
      ).packet(0);
      expect(p.length, 34);
      expect(head(p, 2), hex('CC 20'));
      expect(p.sublist(2, 6), hex('01 00 00 00')); // Zone_Sel0
      expect(p[2 + 9], 1); // Mode_Sel
      expect(p[2 + 10], 0xFF); // brightness 9 clamped to level 8 (0xFF)
      expect(p.sublist(2 + 12, 2 + 16), hex('33 22 11 00'));
      expect(p.sublist(2 + 20, 2 + 22), [0, 0]);
      const dim = IteHardwareEffect(
        IteHardwareMode.staticColor,
        color: (0, 0, 0),
        brightness: 2,
      );
      expect(dim.dataFormat(2)[10], 0x4D);
      expect(dim.dataFormat(2)[0], 4);
    });

    test('DataFormat_8297 Pulse', () {
      final d = const IteHardwareEffect(
        IteHardwareMode.pulse,
        color: (255, 0, 0),
        speed: 9,
        brightness: 3,
      ).dataFormat(3);
      expect(d[9], 2);
      expect(d[10], 100);
      expect(d.sublist(20, 26), hex('90 01 90 01 C8 00')); // 400,400,200
      expect(d[29], 1);
      expect(d.sublist(12, 16), hex('00 00 FF 00'));
    });

    test('other modes', () {
      List<int> f(IteHardwareMode m, int sp) => IteHardwareEffect(
        m,
        color: (0, 0, 0),
        speed: sp,
        brightness: 4,
      ).dataFormat(0);
      final flash = f(IteHardwareMode.flash, 0);
      expect([flash[9], flash[29], flash[30], flash[10]], [3, 1, 1, 0x80]);
      expect(flash.sublist(20, 26), hex('64 00 64 00 60 09')); // 100,100,2400
      final dflash = f(IteHardwareMode.doubleFlash, 9);
      expect([dflash[9], dflash[30]], [3, 2]);
      expect(dflash.sublist(24, 26), [800 & 0xFF, 800 >> 8]);
      final cycle = f(IteHardwareMode.colorCycle, 1);
      expect(
        [
          cycle[9],
          cycle[28],
          cycle[20] | cycle[21] << 8,
          cycle[22] | cycle[23] << 8,
        ],
        [4, 7, 1100, 900],
      );
      final wave = f(IteHardwareMode.wave, 9);
      expect(
        [wave[9], wave[28], wave[29], wave[20], wave[22]],
        [6, 7, 1, 30, 30],
      );
    });

    test('CC 60 calibration (ITE §2.3)', () {
      final info = parseIteInfo(infoTable())!;
      expect(info.firmware, '4.0.23.0');
      final c = info.calibration!;
      expect(
        [c.strip3, c.strip0, c.strip1, c.strip2],
        [0x00020100, 0x00010002, 0x00010002, 0x00010002],
      );
      expect(c.chipId, 0x57010100);
      expect(c.strip4, 0);
      expect(info.zoneOrder, IteColorOrder.bgr);
      expect(info.stripOrder, IteColorOrder.grb);
      expect(info.stripOrder.bytes(10, 20, 30), [20, 10, 30]);
      expect(parseIteInfo(infoTable().sublist(0, 40))!.calibration, isNull);
      expect(
        parseIteInfo(infoTable().sublist(0, 40))!.stripOrder,
        IteColorOrder.grb,
      );
    });
  });

  group('guards', () {
    test('forbidden commands throw', () {
      for (final c in [
        'CC 59 00 00 03 01 02 03',
        'CC 32 03',
        'CC 32 02',
        'CC 5E',
        'CC 47 01',
        'CC 48',
      ]) {
        expect(
          () => checkIteCommand(hex(c)),
          throwsA(isA<IteForbiddenCommand>()),
          reason: c,
        );
      }
      expect(
        () => iteStreamPacket(0x59, 0, [1, 2, 3]),
        throwsA(isA<IteForbiddenCommand>()),
      );
      for (final c in [
        'CC 60',
        'CC 32 01',
        'CC 34 01',
        'CC 28 FF',
        'CC 58 00 00 03 01 02 03',
      ]) {
        checkIteCommand(hex(c));
      }
    });
  });

  group('IteController', () {
    late FakeIte fake;
    late IteController ctl;
    late List<Duration> delays;
    setUp(() {
      delays = [];
      fake = FakeIte();
      ctl = IteController(
        () => fake,
        pause: (_) {},
        delay: (d) async => delays.add(d),
      );
    });

    test('init: CC 60, CC 32 01, CC 34 01', () {
      expect(ctl.init(), isTrue);
      expect(fake.sent, [hex('CC 60'), hex('CC 32 01'), hex('CC 34 01')]);
      expect(ctl.info?.description, 'IT5701-GIGABYTE V4.0.23.0');
      expect(ctl.info?.firmware, '4.0.23.0');
    });

    test('streamCase initializes automatically and does not resend CC 34', () {
      final rgb = List.filled(141, 7);
      expect(ctl.streamCase(rgb), isTrue);
      expect(ctl.streamCase(rgb), isTrue);
      expect(fake.sent.where((p) => p[1] == 0x34).length, 1);
      expect(fake.sent.where((p) => p[1] == 0x58).length, 6);
    });

    test('setZoneColors resends only changed values', () {
      ctl.init();
      fake.sent.clear();
      ctl.setZoneColors({0x20: (0, 0, 255), 0x22: (1, 2, 3)});
      expect(fake.sent.length, 3);
      expect(fake.sent[0].sublist(0x0E, 0x11), hex('FF 00 00'));
      expect(fake.sent[2], hex('CC 28 FF'));
      fake.sent.clear();
      ctl.setZoneColors({0x20: (0, 0, 255), 0x22: (1, 2, 4)});
      expect(fake.sent.length, 2);
      fake.sent.clear();
      ctl.setZoneColors({0x20: (0, 0, 255)});
      expect(fake.sent, isEmpty);
    });

    test('setZoneEffects: all CC 2z, 100 ms, one CC 28 mask, 25 ms', () async {
      ctl.init();
      fake.sent.clear();
      const wave = IteHardwareEffect(IteHardwareMode.wave, color: (1, 2, 3));
      expect(await ctl.setZoneEffects({3: wave, 0: wave}), isTrue);
      expect(fake.sent.length, 3);
      expect(head(fake.sent[0], 2), hex('CC 23'));
      expect(head(fake.sent[1], 2), hex('CC 20'));
      expect(fake.sent[2], hex('CC 28 09'));
      expect(delays, [
        const Duration(milliseconds: 100),
        const Duration(milliseconds: 25),
      ]);
    });

    test('setZoneEffects forgets the static cache of the zone', () async {
      ctl.init();
      ctl.setZoneColors({0x23: (1, 2, 3)});
      await ctl.setZoneEffects({
        3: const IteHardwareEffect(IteHardwareMode.pulse, color: (1, 2, 3)),
      });
      fake.sent.clear();
      ctl.setZoneColors({0x23: (1, 2, 3)});
      expect(fake.sent, isNotEmpty);
    });

    test('init clears the static cache (resume resends)', () {
      ctl.init();
      ctl.setZoneColors({0x20: (0, 0, 255)});
      fake.sent.clear();
      ctl.setZoneColors({0x20: (0, 0, 255)});
      expect(fake.sent, isEmpty);
      ctl.init();
      fake.sent.clear();
      ctl.setZoneColors({0x20: (0, 0, 255)});
      expect(fake.sent, isNotEmpty);
    });

    test('dispose: no I/O, no reopen, idempotent', () async {
      var opens = 0;
      final c = IteController(
        () {
          opens++;
          return fake;
        },
        pause: (_) {},
        delay: (_) async {},
      );
      c.init();
      c.dispose();
      c.dispose();
      fake.sent.clear();
      expect(c.init(), isFalse);
      expect(c.streamCase(List.filled(141, 1)), isFalse);
      expect(c.setZoneColors({0x20: (1, 2, 3)}), isFalse);
      expect(c.allOff(), isFalse);
      expect(
        await c.setZoneEffects({
          1: const IteHardwareEffect(IteHardwareMode.wave, color: (1, 2, 3)),
        }),
        isFalse,
      );
      expect(fake.sent, isEmpty);
      expect(opens, 1);
    });

    test('dispose during the effect wait: CC 28 is not sent', () async {
      late IteController c;
      c = IteController(
        () => fake,
        pause: (_) {},
        delay: (_) async => c.dispose(),
      );
      c.init();
      fake.sent.clear();
      final ok = await c.setZoneEffects({
        1: const IteHardwareEffect(IteHardwareMode.wave, color: (1, 2, 3)),
      });
      expect(ok, isFalse);
      expect(fake.sent.map((p) => p[1]), [0x21]);
    });

    test('allOff and re-init on the next send', () {
      ctl.init();
      fake.sent.clear();
      expect(ctl.allOff(), isTrue);
      final cmds = fake.sent.map((p) => p[1]).toList();
      // Never the empty 12 V zones (0x21, 0x24) nor D_LED2 (0x26).
      expect(cmds, [0x20, 0x22, 0x23, 0x25, 0x28, 0x32, 0x58, 0x58, 0x58]);
      expect(fake.sent[4], hex('CC 28 FF'));
      expect(fake.sent[6].sublist(5).every((b) => b == 0), isTrue);
      fake.sent.clear();
      ctl.streamCase(List.filled(141, 1));
      expect(fake.sent.take(3).toList(), [
        hex('CC 60'),
        hex('CC 32 01'),
        hex('CC 34 01'),
      ]);
    });

    test('HID failure returns false and reopens after retry', () {
      ctl.init();
      fake.failNext = true;
      expect(ctl.streamCase(List.filled(141, 1)), isFalse);
      expect(ctl.streamCase(List.filled(141, 1)), isFalse); // within the retry
    });

    test('a failure in every send path returns false and closes', () async {
      IteController fresh() => IteController(
        () => fake,
        pause: (_) {},
        delay: (_) async {},
        retry: Duration.zero,
      );

      // init (CC 60)
      var c = fresh();
      fake.failNext = true;
      expect(c.init(), isFalse);
      expect(c.info, isNull);

      // streamCase (CC 58)
      c = fresh();
      c.init();
      fake.failNext = true;
      expect(c.streamCase(List.filled(141, 1)), isFalse);

      // setZoneColors (CC 2z)
      c = fresh();
      c.init();
      fake.failNext = true;
      expect(c.setZoneColors({0x20: (1, 2, 3)}), isFalse);

      // setZoneEffects (CC 2z)
      c = fresh();
      c.init();
      fake.failNext = true;
      expect(
        await c.setZoneEffects({
          1: const IteHardwareEffect(IteHardwareMode.wave, color: (1, 2, 3)),
        }),
        isFalse,
      );

      // allOff (static zones)
      c = fresh();
      c.init();
      fake.failNext = true;
      expect(c.allOff(), isFalse);

      // After a failure the controller is closed: the next call reopens.
      fake.failNext = false;
      expect(c.streamCase(List.filled(141, 1)), isTrue);
    });

    test('without a device', () {
      expect(IteController(() => null, pause: (_) {}).init(), isFalse);
    });
  });
}
