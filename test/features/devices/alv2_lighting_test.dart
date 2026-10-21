import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/core/platform/hidapi_ffi.dart';
import 'package:lumivent/features/devices/infrastructure/drivers/alv2/hub.dart';
import 'package:lumivent/features/devices/infrastructure/drivers/alv2/lighting.dart';
import 'package:lumivent/features/devices/infrastructure/drivers/alv2/protocol.dart';

List<int> hex(String s) => [
  for (final b in s.split(' ')) int.parse(b, radix: 16),
];

const red = [255, 0, 0],
    green = [0, 255, 0],
    blue = [0, 0, 255],
    yellow = [255, 255, 0];

List<int> rgb(List<List<int>> cs) => [for (final c in cs) ...c];

/// Fake clock: sleep and delay only advance time.
class FakeClock {
  DateTime t = DateTime(2026);
  DateTime now() => t;
  void sleep(Duration d) => t = t.add(d);
  Future<void> delay(Duration d) async {
    await Future<void>.value();
    t = t.add(d);
  }
}

class Sent {
  Sent(this.at, this.kind, this.bytes, this.length);
  final DateTime at;
  final String kind;
  final List<int> bytes;
  final int length;
}

class FakeTransport implements Alv2Transport {
  FakeTransport(this.clock);
  final FakeClock clock;
  final sent = <Sent>[];
  bool failNext = false;

  /// Raw input report returned by `getInput` (zeros when null).
  Uint8List? input;

  void _log(String k, List<int> d, int l) {
    if (failNext) {
      failNext = false;
      throw HidException('falha');
    }
    sent.add(Sent(clock.t, k, List.of(d), l));
  }

  @override
  void sendFeature(List<int> data, int length) => _log('feature', data, length);
  @override
  void write(List<int> data, int length) => _log('output', data, length);
  @override
  Uint8List getInput(int reportId, int length) => input ?? Uint8List(length);
  @override
  void close() {}
}

(Alv2Hub, FakeTransport, FakeClock) fakeHub() {
  final clock = FakeClock();
  final tr = FakeTransport(clock);
  final hub = Alv2Hub.withTransport(
    tr,
    now: clock.now,
    sleeper: clock.sleep,
    delay: clock.delay,
  );
  return (hub, tr, clock);
}

void main() {
  group('lighting packets', () {
    test('effect, frame, quantity, merge, sync, and ping', () {
      expect(
        alv2EffectPacket(2, 0x01, 0x02, 0x00, 0x00),
        hex('E0 12 01 02 00 00'),
      );
      expect(alv2FramePacket, hex('E0 60 00 01'));
      expect(alv2QuantityPacket(3, 1), hex('E0 10 60 04 01 00'));
      expect(alv2QuantityPacket(0, 9)[4], 6);
      expect(
        alv2MergeOrderPacket([0, 1, 2, 3]),
        hex('E0 10 63 00 01 02 03 08'),
      );
      expect(alv2ArgbSyncOffPacket, hex('E0 10 61 00 00 00'));
      expect(alv2PingPacket(1), hex('E0 12 36 00 00 02'));
      expect(alv2MergePingPacket(2), hex('E0 10 50 02 00 00'));
      expect(alv2OutputLength, 353);
    });

    test('colors use R,B,G order', () {
      expect(
        alv2ColorPacket(2, [1, 2, 3, 4, 5, 6]),
        hex('E0 32 01 03 02 04 06 05'),
      );
    });

    test('speed and brightness conversions', () {
      expect(
        [for (var i = 0; i < 5; i++) alv2SpeedByte(i)],
        [0x02, 0x01, 0x00, 0xFF, 0xFE],
      );
      expect(
        [for (var i = 0; i < 5; i++) alv2BrightnessByte(i)],
        [0x08, 0x03, 0x02, 0x01, 0x00],
      );
    });
  });

  group('modes', () {
    test('AL-V2 §3 table', () {
      expect(
        Alv2LightMode.values.where((m) => m.scope == Alv2LightScope.whole),
        hasLength(26),
      );
      expect(
        Alv2LightMode.values.where((m) => m.scope == Alv2LightScope.merge),
        hasLength(10),
      );
      expect(Alv2LightMode.byName('Rainbow')!.byte, 0x2B);
      expect(Alv2LightMode.byName('Runway_Merge')!.byte, 0x46);
      expect(Alv2LightMode.byName('ColorCycle_Outer')!.byte, 0x1C);
      expect(Alv2LightMode.byUiId(93)!.firmwareName, 'StaticColorful_Outer');
      expect(
        Alv2LightMode.staticColor.splitInner,
        Alv2LightMode.staticColorInner,
      );
      expect(
        Alv2LightMode.staticColor.splitOuter,
        Alv2LightMode.staticColorOuter,
      );
      expect(Alv2LightMode.rainbow.splitInner, isNull);
      expect(
        {for (final m in Alv2LightMode.values) m.uiId}.length,
        Alv2LightMode.values.length,
      );
    });

    test('§6 metadata', () {
      expect(Alv2LightMode.staticColor.hasSpeed, isFalse);
      expect(Alv2LightMode.staticColor.colorCount, 6);
      expect(Alv2LightMode.rainbow.hasDirection, isTrue);
      expect(Alv2LightMode.warning.meta.defaultSpeedLevel, 2);
      expect(Alv2LightMode.spanningTeacups.meta.defaultDirection, 1);
      expect(Alv2LightMode.runwayInner.colorCount, 2); // inherited from Runway
      expect(
        Alv2LightMode.staticColor.meta.defaultColors,
        rgb([
          red,
          blue,
          green,
          yellow,
          [255, 128, 0],
          [0, 255, 255],
        ]),
      );
    });
  });

  group('color normalization', () {
    test('empty list: no color packet', () {
      expect(alv2NormalizeColors(Alv2LightMode.rainbow, const []), isEmpty);
      final w = alv2WholeWrites(0, const Alv2Effect(Alv2LightMode.rainbow));
      expect(w.single.packets, hasLength(1));
    });

    test('StaticColor_Inner: 48 LEDs, fans 1/2/3 = R/G/B, 8 LEDs each', () {
      final n = alv2NormalizeColors(
        Alv2LightMode.staticColorInner,
        rgb([red, green, blue]),
      );
      expect(n, hasLength(48 * 3));
      for (var f = 0; f < 3; f++) {
        for (var l = 0; l < 8; l++) {
          expect(
            n.sublist((f * 8 + l) * 3, (f * 8 + l) * 3 + 3),
            [red, green, blue][f],
          );
        }
      }
      expect(n.sublist(24 * 3), everyElement(0));
    });

    test('StaticColor_Outer: 72 LEDs, 12 per fan', () {
      final n = alv2NormalizeColors(
        Alv2LightMode.staticColorOuter,
        rgb([red, green]),
      );
      expect(n, hasLength(72 * 3));
      expect(n.sublist(11 * 3, 12 * 3), red);
      expect(n.sublist(12 * 3, 13 * 3), green);
    });

    test('StaticColorful_Outer: R/G/B/Y corners × 3 LEDs on each fan', () {
      final n = alv2NormalizeColors(
        Alv2LightMode.staticColorfulOuter,
        rgb([red, green, blue, yellow]),
      );
      expect(n, hasLength(72 * 3));
      for (final f in [0, 5]) {
        for (var c = 0; c < 4; c++) {
          for (var l = 0; l < 3; l++) {
            final i = f * 12 + c * 3 + l;
            expect(n.sublist(i * 3, i * 3 + 3), [red, green, blue, yellow][c]);
          }
        }
      }
    });

    test('Meteor is cyclic and other modes pad with black (36)', () {
      final m = alv2NormalizeColors(
        Alv2LightMode.meteor,
        rgb([red, green, blue]),
      );
      expect(m, hasLength(36 * 3));
      expect(
        [for (var j = 0; j < 6; j++) m.sublist(j * 3, j * 3 + 3)],
        [red, green, blue, red, green, blue],
      );
      expect(m.sublist(6 * 3, 6 * 3 + 3), red); // second block repeats
      final r = alv2NormalizeColors(Alv2LightMode.runway, rgb([red, green]));
      expect(r, hasLength(36 * 3));
      expect(r.sublist(2 * 3, 3 * 3), [0, 0, 0]);
      expect(r.sublist(6 * 3, 6 * 3 + 3), red);
    });
  });

  group('port writes', () {
    test(
      'StaticColor becomes 62/92 on ports 2g/2g+1, static, scaled brightness',
      () {
        final w = alv2WholeWrites(
          1,
          Alv2Effect(
            Alv2LightMode.staticColor,
            colors: rgb([
              [200, 100, 50],
            ]),
            brightnessLevel: 2,
          ),
        );
        expect([for (final p in w) p.port], [3, 2]);
        expect(w[1].mode, 0x01);
        expect(w[1].brightness, 0x02);
        expect(w[1].colors!.sublist(0, 3), [100, 50, 25]); // 50 %
        expect(w[0].colors, hasLength(72 * 3));
        expect(w[1].colors, hasLength(48 * 3));
        expect(w[1].packets.first.output, isTrue);
        expect(w[1].packets.first.bytes.sublist(0, 5), hex('E0 32 64 19 32'));
      },
    );

    test('whole-fan mode without split writes only port 2g', () {
      final w = alv2WholeWrites(
        2,
        Alv2Effect(Alv2LightMode.rainbow, speedLevel: 4, direction: 1),
      );
      expect(w, hasLength(1));
      expect(w.single.packets.single.bytes, hex('E0 14 2B FE 01 00'));
    });

    test('inner + outer pair', () {
      final w = alv2PairWrites(
        0,
        Alv2Effect(Alv2LightMode.staticColorInner, colors: rgb([red])),
        Alv2Effect(
          Alv2LightMode.staticColorfulOuter,
          colors: rgb([red, green, blue, yellow]),
        ),
      );
      expect([for (final p in w) p.port], [1, 0]);
      expect(w[0].colors, hasLength(72 * 3));
    });

    test(
      'Runway merge: port 0 with 0x46 and ports 1–7 on disabled Rainbow',
      () {
        final w = alv2MergeWrites(
          Alv2Effect(Alv2LightMode.runwayMerge, colors: rgb([red, blue])),
        );
        expect([for (final p in w) p.port], [7, 6, 5, 4, 3, 2, 1, 0]);
        expect(w.last.mode, 0x46);
        expect(w.last.colors, hasLength(36 * 3));
        for (final p in w.take(7)) {
          expect(
            p.packets.single.bytes,
            hex('E0 ${(0x10 | p.port).toRadixString(16)} 2B 00 00 08'),
          );
        }
      },
    );

    test(
      'group 1 canvas with 3 fans: 24/36 LEDs, no padding for absent fans',
      () {
        final leds = [
          for (var i = 0; i < 60; i++) ...[i + 1, 0, 0],
        ]; // LED i = (i+1, 0, 0)
        final w = alv2CanvasWrites(1, 3, leds);
        expect([for (final p in w) p.port], [3, 2]);
        final inner = w[1].colors!, outer = w[0].colors!;
        expect(inner, hasLength(24 * 3));
        expect(outer, hasLength(36 * 3));
        expect(inner.sublist(0, 3), [1, 0, 0]); // fan 0, LED 0
        expect(inner.sublist(8 * 3, 8 * 3 + 3), [
          21,
          0,
          0,
        ]); // fan 1, LED 0 of the inner ring = LED 20
        expect(outer.sublist(0, 3), [
          9,
          0,
          0,
        ]); // fan 0, 1st of the outer = LED 8
        expect(outer.sublist(12 * 3, 12 * 3 + 3), [29, 0, 0]);
        for (final p in w) {
          expect(
            [p.mode, p.speed, p.direction, p.brightness],
            [0x01, 0x02, 0, 0],
          );
        }
      },
    );

    test('canvas bytes: speed 02 commit and size follow the fan count', () {
      final leds = List.filled(60 * 3, 7);
      for (final (fans, innerLen, outerLen) in [(1, 8, 12), (3, 24, 36)]) {
        final w = alv2CanvasWrites(0, fans, leds);
        expect(w[0].colors, hasLength(outerLen * 3));
        expect(w[1].colors, hasLength(innerLen * 3));
        expect(w[0].packets.last.bytes, hex('E0 11 01 02 00 00'));
        expect(w[1].packets.last.bytes, hex('E0 10 01 02 00 00'));
        expect(w[0].packets.first.bytes, hasLength(2 + outerLen * 3));
      }
    });

    test('canvas with 0 fans writes nothing', () {
      expect(alv2CanvasWrites(2, 0, const []), isEmpty);
    });

    test('turn off: brightness 08 on every port, no colors', () {
      final w = alv2OffWrites();
      expect(w, hasLength(8));
      expect([for (final p in w) p.port], [7, 6, 5, 4, 3, 2, 1, 0]);
      expect(w.every((p) => p.brightness == 0x08 && p.colors == null), isTrue);
    });

    test('service order between groups: highest port first', () {
      final all = alv2ServiceOrder([
        ...alv2WholeWrites(
          0,
          Alv2Effect(Alv2LightMode.staticColor, colors: rgb([red])),
        ),
        ...alv2WholeWrites(
          1,
          Alv2Effect(Alv2LightMode.staticColor, colors: rgb([red])),
        ),
      ]);
      expect([for (final p in all) p.port], [3, 2, 1, 0]);
    });
  });

  group('hub', () {
    test('sendLighting: colors by output, effect by feature, frame last, 5 ms pause', () async {
      final (hub, tr, _) = fakeHub();
      final ok = await hub.sendLighting(
        alv2WholeWrites(
          0,
          Alv2Effect(Alv2LightMode.staticColor, colors: rgb([red])),
        ),
      );
      expect(ok, isTrue);
      expect(
        [for (final s in tr.sent) s.kind],
        ['output', 'feature', 'output', 'feature', 'feature'],
      );
      expect(tr.sent[0].length, 353);
      expect(tr.sent[1].length, 7);
      expect(tr.sent.last.bytes, hex('E0 60 00 01'));
      for (var i = 1; i < tr.sent.length; i++) {
        expect(tr.sent[i].at.difference(tr.sent[i - 1].at), alv2LightingGap);
      }
    });

    test('streamCanvas: 2 ms gap, no frame, unpadded reports', () async {
      final (hub, tr, _) = fakeHub();
      final ok = await hub.streamCanvas(
        alv2CanvasWrites(1, 1, List.filled(60, 9)),
      );
      expect(ok, isTrue);
      expect(
        [for (final s in tr.sent) s.kind],
        ['output', 'feature', 'output', 'feature'],
      );
      expect(tr.sent.any((s) => s.bytes[1] == 0x60), isFalse);
      expect(tr.sent[0].length, tr.sent[0].bytes.length); // 2 + 12 × 3
      expect(tr.sent[0].length, 38);
      expect(tr.sent[2].length, 26);
      for (var i = 1; i < tr.sent.length; i++) {
        expect(tr.sent[i].at.difference(tr.sent[i - 1].at), alv2StreamGap);
      }
      expect(alv2StreamGap, const Duration(milliseconds: 2));
    });

    test(
      'streamCanvas waits for the queue and the 20 ms control pause',
      () async {
        final (hub, tr, _) = fakeHub();
        final a = hub.sendLighting([const Alv2PortWrite(port: 0, mode: 1)]);
        final b = hub.streamCanvas(alv2CanvasWrites(0, 1, List.filled(60, 9)));
        await Future.wait([a, b]);
        // sendLighting (effect + frame) entirely before the stream.
        expect(tr.sent[1].bytes, hex('E0 60 00 01'));
        expect(tr.sent[2].bytes[1], 0x31);
        expect(tr.sent[2].length, tr.sent[2].bytes.length);
        expect(tr.sent[2].at.difference(tr.sent[1].at), alv2LightingGap);

        final t0 = tr.sent.last.at;
        expect(hub.setDuty(0, 50), isTrue);
        // Control packets keep the vendor software's 20 ms after any packet, even a
        // 2 ms stream one (stream-squeezed duties slowed the rear fan).
        expect(tr.sent.last.at.difference(t0), alv2PacketGap);
        final t1 = tr.sent.last.at;
        await hub.streamCanvas(alv2CanvasWrites(0, 1, List.filled(60, 9)));
        expect(tr.sent[tr.sent.length - 4].at.difference(t1), alv2PacketGap);
      },
    );

    test('padded output report is still 353 bytes outside streaming', () async {
      final (hub, tr, _) = fakeHub();
      await hub.sendLighting(alv2CanvasWrites(0, 1, List.filled(60, 9)));
      expect(tr.sent[0].length, 353);
    });

    test(
      'duty after lighting waits until 20 ms after the last packet',
      () async {
        final (hub, tr, clock) = fakeHub();
        await hub.sendLighting(alv2OffWrites().take(1).toList(), frame: false);
        final t0 = tr.sent.last.at;
        clock.t = t0.add(const Duration(milliseconds: 3));
        expect(hub.setDuty(0, 50), isTrue);
        // 20 ms after the last packet (17 ms were missing), not the 5 ms light gap.
        expect(tr.sent.last.at.difference(t0), alv2PacketGap);
        // After duty, light waits 20 ms.
        final t1 = tr.sent.last.at;
        await hub.sendLighting([
          const Alv2PortWrite(port: 0, mode: 1),
        ], frame: false);
        expect(tr.sent.last.at.difference(t1), alv2PacketGap);
      },
    );

    test('20 ms control pause between sync packets', () {
      final (hub, tr, _) = fakeHub();
      hub.setMotherboardSync([true, false, false, false]);
      for (var i = 1; i < 4; i++) {
        expect(tr.sent[i].at.difference(tr.sent[i - 1].at), alv2PacketGap);
      }
    });

    test('readRpm sends E0 50 00 and parses the input report', () {
      final (hub, tr, clock) = fakeHub();
      final raw = Uint8List(alv2InputLength)
        ..setRange(0, 10, hex('E0 F0 00 00 03 ED 04 CE 04 CE'));
      tr.input = raw;
      final t0 = clock.t;
      expect(hub.readRpm(), [0, 1005, 1230, 1230]);
      expect(tr.sent.single.bytes, hex('E0 50 00'));
      // A pause before reading the (shared) input buffer.
      expect(clock.t.difference(t0), alv2PacketGap);
    });

    test('readRpm returns null on a HID failure', () {
      final (hub, tr, _) = fakeHub();
      tr.failNext = true;
      expect(hub.readRpm(), isNull);
    });

    test('quantity, merge order (7 bytes), and disable-only ARGB sync', () {
      final (hub, tr, _) = fakeHub();
      expect(hub.setQuantity(3, 1), isTrue);
      expect(hub.setMergeOrder([0, 1, 2, 3]), isTrue);
      expect(hub.disableArgbSync(), isTrue);
      expect(hub.setQuantity(0, 7), isFalse);
      expect(hub.setMergeOrder([0, 1, 2]), isFalse);
      expect(tr.sent.map((s) => s.bytes).toList(), [
        hex('E0 10 60 04 01 00'),
        hex('E0 10 63 00 01 02 03'),
        hex('E0 10 61 00 00 00'),
      ]);
    });

    test('identify: ping, 2500 ms, frame', () async {
      final (hub, tr, _) = fakeHub();
      expect(await hub.identify(1), isTrue);
      expect(tr.sent.map((s) => s.bytes).toList(), [
        hex('E0 12 36 00 00 02'),
        hex('E0 60 00 01'),
      ]);
      expect(
        tr.sent[1].at.difference(tr.sent[0].at),
        greaterThanOrEqualTo(const Duration(milliseconds: 2500)),
      );
    });

    test('two simultaneous sendLighting calls do not interleave', () async {
      final (hub, tr, _) = fakeHub();
      final a = hub.sendLighting([
        const Alv2PortWrite(port: 0, mode: 1),
        const Alv2PortWrite(port: 1, mode: 1),
      ]);
      final b = hub.sendLighting([
        const Alv2PortWrite(port: 2, mode: 2),
        const Alv2PortWrite(port: 3, mode: 2),
      ]);
      expect(await Future.wait([a, b]), [true, true]);
      expect(
        [for (final s in tr.sent) s.bytes[1]],
        [0x10, 0x11, 0x60, 0x12, 0x13, 0x60],
      );
    });

    test('HID error: returns false and closes the transport', () async {
      final (hub, tr, _) = fakeHub();
      tr.failNext = true;
      expect(
        await hub.sendLighting([const Alv2PortWrite(port: 0, mode: 1)]),
        isFalse,
      );
      expect(hub.setDuty(0, 50), isFalse); // no transport and no hidapi
    });

    test(
      'dispose during sendLighting: no packet after it, returns false',
      () async {
        final clock = FakeClock();
        final tr = FakeTransport(clock);
        late final Alv2Hub hub;
        hub = Alv2Hub.withTransport(
          tr,
          now: clock.now,
          sleeper: clock.sleep,
          // The pause after the first packet: dispose happens here.
          delay: (d) async {
            hub.dispose();
            await clock.delay(d);
          },
        );
        final ok = await hub.sendLighting([
          const Alv2PortWrite(port: 0, mode: 1),
          const Alv2PortWrite(port: 1, mode: 1),
        ]);
        expect(ok, isFalse);
        expect(tr.sent, hasLength(1));
      },
    );

    test('methods after dispose return false/null without I/O', () async {
      final (hub, tr, _) = fakeHub();
      hub.dispose();
      hub.dispose(); // second call does nothing
      final before = tr.sent.length;
      expect(hub.readRpm(), isNull);
      expect(hub.setDuty(0, 50), isFalse);
      expect(hub.setMotherboardSync([true, false, false, false]), isFalse);
      expect(hub.setQuantity(0, 1), isFalse);
      expect(hub.setMergeOrder([0, 1, 2, 3]), isFalse);
      expect(hub.disableArgbSync(), isFalse);
      expect(await hub.sendLighting(alv2OffWrites()), isFalse);
      expect(await hub.identify(1), isFalse);
      expect(tr.sent, hasLength(before));
    });
  });
  group('checkAlv2Packet (central guard)', () {
    test('accepts the packets the app sends', () {
      for (final c in [
        'E0 50 00',
        'E0 21 00 64',
        'E0 10 62 11 00 00',
        'E0 10 60 04 01 00',
        'E0 10 63 00 01 02 03',
        'E0 10 61 00 00 00',
        'E0 12 36 00 00 02',
        'E0 10 50 02 00 00',
        'E0 60 00 01',
      ]) {
        checkAlv2Packet(hex(c), output: false);
      }
      checkAlv2Packet(alv2ColorPacket(7, [1, 2, 3]), output: true);
      checkAlv2Packet(
        alv2ColorPacket(0, List.filled(117 * 3, 1)),
        output: true,
      );
    });

    test('refuses enabling the motherboard ARGB sync', () {
      for (final c in ['E0 10 61 01 00 00', 'E0 10 61 00 00 01', 'E0 10 61']) {
        expect(
          () => checkAlv2Packet(hex(c), output: false),
          throwsA(isA<Alv2ForbiddenPacket>()),
          reason: c,
        );
      }
    });

    test('refuses wrong report ID, size and port', () {
      expect(
        () => checkAlv2Packet(hex('E1 10 00'), output: false),
        throwsA(isA<Alv2ForbiddenPacket>()),
      );
      expect(
        () => checkAlv2Packet(List.filled(8, 0xE0), output: false),
        throwsA(isA<Alv2ForbiddenPacket>()),
      );
      expect(
        () => checkAlv2Packet(List.filled(354, 0xE0)..[1] = 0x30, output: true),
        throwsA(isA<Alv2ForbiddenPacket>()),
      );
      expect(
        () => checkAlv2Packet(hex('E0 38 01 02 03'), output: true),
        throwsA(isA<Alv2ForbiddenPacket>()),
      );
      expect(
        () => checkAlv2Packet(hex('E0 18 01 02 00 00'), output: false),
        throwsA(isA<Alv2ForbiddenPacket>()),
      );
    });

    test('builders validate ranges with ArgumentError', () {
      expect(() => alv2EffectPacket(8, 1, 0, 0, 0), throwsArgumentError);
      expect(() => alv2EffectPacket(-1, 1, 0, 0, 0), throwsArgumentError);
      expect(() => alv2ColorPacket(9, [1, 2, 3]), throwsArgumentError);
      expect(() => alv2ColorPacket(0, [1, 2]), throwsArgumentError);
      expect(() => alv2DutyPacket(4, 50), throwsArgumentError);
      expect(() => alv2QuantityPacket(-1, 1), throwsArgumentError);
      expect(() => alv2MergeOrderPacket([0, 1, 2, 4]), throwsArgumentError);
      expect(() => alv2MergeOrderPacket([0, 1, 2]), throwsArgumentError);
      expect(
        () => alv2MotherboardSyncPacket(0, [true, false]),
        throwsArgumentError,
      );
      expect(() => alv2PingPacket(4), throwsArgumentError);
      expect(() => alv2MergePingPacket(5), throwsArgumentError);
    });

    test('a forbidden packet explains itself', () {
      expect(
        Alv2ForbiddenPacket('teste').toString(),
        'AL V2 packet blocked: teste',
      );
    });

    test('the hub refuses a forbidden packet before any I/O', () async {
      final (hub, tr, _) = fakeHub();
      expect(
        () => hub.sendLighting([const Alv2PortWrite(port: 9, mode: 1)]),
        throwsArgumentError,
      );
      expect(tr.sent, isEmpty);
    });
  });

  group('priority send', () {
    test('turn-off skips a pending identify and drops queued frames', () async {
      final (hub, tr, _) = fakeHub();
      final identify = hub.identify(1);
      final stale = hub.sendLighting([const Alv2PortWrite(port: 2, mode: 1)]);
      final off = hub.sendLighting(alv2OffWrites(), priority: true);
      expect(await off, isTrue);
      expect(await identify, isFalse); // frame commit after the wait is skipped
      expect(await stale, isFalse);
      // ping, then the off writes; nothing relights afterwards.
      final last = tr.sent.last;
      expect(last.bytes, alv2FramePacket);
      expect(
        tr.sent.where((s) => s.bytes[1] == 0x12 && s.bytes[2] == 1),
        isEmpty,
      );
    });
  });
}
