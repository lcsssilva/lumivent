import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/core/engine/engine_host.dart';
import 'package:lumivent/core/persistence/config_store.dart';
import 'package:lumivent/core/platform/hidapi_ffi.dart' show HidException;
import 'package:lumivent/features/devices/infrastructure/drivers/alv2/hub.dart';
import 'package:lumivent/features/devices/infrastructure/drivers/alv2/hub_worker.dart';
import 'package:lumivent/features/devices/infrastructure/drivers/ite5702/controller.dart';
import 'package:lumivent/features/devices/infrastructure/drivers/kingston_fury/controller.dart';
import 'package:lumivent/features/lighting/infrastructure/device_light_outputs.dart';
import 'package:lumivent/features/lighting/infrastructure/light_io_worker.dart';
import 'package:lumivent/features/lighting/lighting.dart';

import '../../fakes.dart';

class _HubTransport implements Alv2Transport {
  final writes = <List<int>>[];

  /// Report length passed to `write` / `sendFeature`, parallel to [writes].
  final lengths = <int>[];
  bool failNext = false;
  void _log(List<int> data, int length) {
    if (failNext) {
      failNext = false;
      throw HidException('hub failure');
    }
    writes.add(List.of(data));
    lengths.add(length);
  }

  @override
  void sendFeature(List<int> data, int length) => _log(data, length);
  @override
  void write(List<int> data, int length) => _log(data, length);
  @override
  Uint8List getInput(int reportId, int length) => Uint8List(length);
  @override
  void close() {}
}

class _IteTransport implements IteTransport {
  final sent = <List<int>>[];
  bool failNext = false;
  @override
  void sendFeature(List<int> data, int length) {
    if (failNext) {
      failNext = false;
      throw HidException('ITE failure');
    }
    sent.add(List.of(data));
  }

  @override
  Uint8List getFeature(int reportId, int length) => Uint8List(64);
  @override
  void close() {}
}

class _FuryBus implements FuryBus {
  final writes = <(int, int, int)>[];
  int opens = 0;

  /// Guard value read from [ddAddress] (all addresses when null).
  int dd = 0;
  int? ddAddress;
  static const _id = [0x46, 0x55, 0x52, 0x59];
  @override
  int readByte(int addr, int reg) =>
      reg == 0xDD && (ddAddress == null || ddAddress == addr) ? dd : 0;
  @override
  int readWord(int addr, int reg) => (_id[reg - 1] << 8) | 0x34;
  @override
  void writeByte(int addr, int reg, int value) =>
      writes.add((addr, reg, value));
  @override
  void quick(int addr) {}
  @override
  void close() {}
}

List<int> hex(String s) => [
  for (final b in s.split(' ')) int.parse(b, radix: 16),
];

void main() {
  group('DeviceLightOutputs over fake drivers', () {
    late _HubTransport hubTr;
    late _IteTransport ite;
    late _FuryBus fury;
    late DeviceLightOutputs out;

    setUp(() {
      hubTr = _HubTransport();
      ite = _IteTransport();
      fury = _FuryBus();
      out = DeviceLightOutputs(
        Alv2HubProxy.local(
          Alv2Hub.withTransport(hubTr, delay: (_) async {}, sleeper: (_) {}),
        ),
        io: LocalLightIo(
          LightIoCore(
            ite: IteController(() => ite, pause: (_) {}, delay: (_) async {}),
            fury: FuryController(open: () => fury),
          ),
        ),
      );
    });

    List<Rgb> leds(int n) => List.filled(n, const Rgb(10, 20, 30));

    test('fan hardware colors are completed with the defaults', () async {
      // Saved list shorter than the mode's color count (6 for StaticColor).
      const config = Alv2HardwareConfig(
        mode: 'StaticColor',
        colors: [Rgb(9, 9, 9)],
      );
      expect(await out.setFanHardware(1, config), isTrue);
      // StaticColor inner ring: 6 fans x 8 LEDs, fan i = color i, bytes R,B,G.
      final colors = hubTr.writes.firstWhere((w) => w[1] == 0x32);
      expect(colors.length, 2 + 6 * 8 * 3);
      expect(colors.sublist(2, 5), [9, 9, 9]); // saved color
      expect(colors.sublist(2 + 8 * 3, 5 + 8 * 3), [0, 255, 0]); // default #2
      expect(colors.sublist(2 + 40 * 3, 5 + 40 * 3), [0, 255, 255]); // #6

      hubTr.writes.clear();
      const empty = Alv2HardwareConfig(mode: 'StaticColor', colors: []);
      expect(await out.setFanHardware(1, empty), isTrue);
      final all = hubTr.writes.firstWhere((w) => w[1] == 0x32);
      expect(all.sublist(2, 5), [255, 0, 0]);
    });

    test('closed outputs reach no driver and close is idempotent', () async {
      expect(await out.initBoard(), isTrue);
      unawaited(out.close());
      unawaited(out.close());
      ite.sent.clear();
      hubTr.writes.clear();
      expect(await out.initBoard(), isFalse);
      expect(await out.sendChassis(leds(47)), isFalse);
      expect(await out.turnBoardOff(), isFalse);
      expect(await out.sendRam(0, leds(12)), isFalse);
      expect(await out.turnRamOff(), isFalse);
      expect(await out.initFans([0, 1, 1, 1]), isFalse);
      expect(await out.turnAllFansOff(), isFalse);
      expect(await out.setBoardZones({0x20: const BoardZoneConfig()}), isFalse);
      expect(ite.sent, isEmpty);
      expect(hubTr.writes, isEmpty);
    });

    test('resume: invalidate makes static colors go out again', () async {
      final zones = leds(3);
      expect(await out.initBoard(), isTrue);
      expect(await out.sendBoardColors(zones), isTrue);
      expect(await out.sendRam(0, leds(12)), isTrue);
      ite.sent.clear();
      fury.writes.clear();
      // Unchanged: both drivers skip the write.
      await out.sendBoardColors(zones);
      await out.sendRam(0, leds(12));
      expect(ite.sent, isEmpty);
      expect(fury.writes, isEmpty);
      // What the engine does on resume.
      out.invalidate();
      expect(await out.initBoard(), isTrue);
      ite.sent.clear();
      expect(await out.sendBoardColors(zones), isTrue);
      expect(await out.sendRam(0, leds(12)), isTrue);
      expect(ite.sent, isNotEmpty);
      expect(fury.writes, isNotEmpty);
    });

    test(
      'turning the board off never writes zones 0x21, 0x24 or 0x26',
      () async {
        expect(await out.initBoard(), isTrue);
        ite.sent.clear();
        expect(await out.turnBoardOff(), isTrue);
        final cmds = ite.sent.map((p) => p[1]).toSet();
        expect(cmds.intersection({0x21, 0x24, 0x26}), isEmpty);
      },
    );

    test(
      'initFans disables ARGB sync, orders the merge and sets quantities',
      () async {
        expect(await out.initFans([0, 3, 2, 1]), isTrue);
        expect(hubTr.writes, [
          hex('E0 10 61 00 00 00'),
          hex('E0 10 63 00 01 02 03'),
          hex('E0 10 60 01 00 00'),
          hex('E0 10 60 02 03 00'),
          hex('E0 10 60 03 02 00'),
          hex('E0 10 60 04 01 00'),
        ]);

        hubTr.writes.clear();
        expect(await out.setFanQuantity([4, 1, 6, 2]), isTrue);
        expect(
          [for (final p in hubTr.writes) p.sublist(3, 5)],
          [
            [1, 4],
            [2, 1],
            [3, 6],
            [4, 2],
          ],
        );
      },
    );

    test('canvas frames: R,B,G order, per-group fan count and black padding', () async {
      final red = List.filled(60, const Rgb(10, 20, 30));
      final blue = List.filled(40, const Rgb(1, 2, 3));
      expect(await out.sendFanFrames({1: red, 2: blue}), isTrue);

      // Highest port first: group 2 (5,4), group 1 (3,2); colors before effect.
      expect(
        [for (final p in hubTr.writes) p[1]],
        [0x35, 0x15, 0x34, 0x14, 0x33, 0x13, 0x32, 0x12],
      );
      // Streaming: no frame commit, reports written unpadded, speed 02.
      expect(hubTr.writes.any((w) => w[1] == 0x60), isFalse);
      expect(hubTr.lengths[0], hubTr.writes[0].length);
      expect(hubTr.writes[1], hex('E0 15 01 02 00 00'));
      final group1Outer = hubTr.writes[4];
      expect(group1Outer.length, 2 + 36 * 3); // 3 fans × 12 LEDs
      expect(group1Outer.sublist(2, 5), [10, 30, 20]); // RGB in, R,B,G out
      final group1Inner = hubTr.writes[6];
      expect(group1Inner.length, 2 + 24 * 3); // 3 fans × 8 LEDs
      final group2Outer = hubTr.writes[0];
      expect(group2Outer.length, 2 + 24 * 3); // 2 fans × 12 LEDs
      expect(group2Outer.sublist(2, 5), [1, 3, 2]);
    });

    test(
      'hardware modes keep the padded report and the frame commit',
      () async {
        hubTr.lengths.clear();
        expect(await out.setFanHardware(1, const Alv2HardwareConfig()), isTrue);
        expect(hubTr.writes.last, hex('E0 60 00 01'));
        expect(hubTr.lengths.last, 7);
        expect(await out.turnAllFansOff(), isTrue);
        expect(hubTr.writes.last, hex('E0 60 00 01'));
      },
    );

    test('fan hardware: whole shape, rings, fallbacks and unknown mode', () async {
      const rainbow = Alv2HardwareConfig(
        mode: 'Rainbow',
        speed: 4,
        directionLeft: true,
        brightness: 1,
      );
      expect(await out.setFanHardware(1, rainbow), isTrue);
      // Feature report only (7-byte limit): speed FE, direction 1, brightness
      // 03, then the frame commit.
      expect(hubTr.writes, [hex('E0 12 2B FE 01 03'), hex('E0 60 00 01')]);

      // PacMan has no whole-fan mode: the outer ring falls back to StaticColor.
      hubTr.writes.clear();
      const pacman = Alv2HardwareConfig(
        scope: Alv2Scope.innerOuter,
        mode: 'PacMan',
        brightness: 0,
      );
      expect(await out.setFanHardware(2, pacman), isTrue);
      final effects = [
        for (final p in hubTr.writes)
          if (p[1] >= 0x10 && p[1] < 0x18) p,
      ];
      expect(effects, [hex('E0 15 01 00 00 08'), hex('E0 14 27 00 00 08')]);

      // Unknown name: StaticColor, so the group is never left undefined.
      hubTr.writes.clear();
      expect(
        await out.setFanHardware(
          3,
          const Alv2HardwareConfig(mode: 'DoesNotExist'),
        ),
        isTrue,
      );
      final fallback = [
        for (final p in hubTr.writes)
          if (p[1] >= 0x10 && p[1] < 0x18) p,
      ];
      // StaticColor is a split mode: outer (port 7) and inner (port 6).
      expect([for (final p in fallback) p[1]], [0x17, 0x16]);
      expect(fallback.every((p) => p[2] == 0x01), isTrue);
    });

    test('merge: supported names only, port 0 carries the mode', () async {
      expect(out.supportsFanMerge('Runway'), isTrue);
      expect(out.supportsFanMerge('Runway_Inner'), isTrue);
      expect(out.supportsFanMerge('Runway_Merge'), isTrue);
      expect(out.supportsFanMerge('Rainbow'), isFalse);

      expect(
        await out.setFanMerge('Rainbow', const Alv2HardwareConfig()),
        isFalse,
      );
      expect(hubTr.writes, isEmpty);

      const config = Alv2HardwareConfig(mode: 'Runway', speed: 1);
      expect(await out.setFanMerge('Runway', config), isTrue);
      final effects = [
        for (final p in hubTr.writes)
          if (p[1] >= 0x10 && p[1] < 0x18) p,
      ];
      expect(effects, hasLength(8));
      expect(
        [for (final p in effects) p[1]],
        [0x17, 0x16, 0x15, 0x14, 0x13, 0x12, 0x11, 0x10],
      );
      for (final idle in effects.take(7)) {
        expect(idle.sublist(2, 4), [0x2B, 0x00]);
        expect(idle.last, 0x08); // brightness 08 = off
      }
      expect(effects.last.sublist(2, 4), [0x46, 0x01]);
    });

    test(
      'group off and all fans off send brightness 08 on every port',
      () async {
        expect(await out.turnFanGroupOff(2), isTrue);
        expect(hubTr.writes, [
          hex('E0 15 2B 00 00 08'),
          hex('E0 14 2B 00 00 08'),
          hex('E0 60 00 01'),
        ]);

        hubTr.writes.clear();
        expect(await out.turnAllFansOff(), isTrue);
        expect(hubTr.writes, hasLength(9));
        expect(
          [for (final p in hubTr.writes.take(8)) p[1]],
          [0x17, 0x16, 0x15, 0x14, 0x13, 0x12, 0x11, 0x10],
        );
        expect(hubTr.writes.take(8).every((p) => p[5] == 0x08), isTrue);
        expect(hubTr.writes.last, hex('E0 60 00 01'));
      },
    );

    test('identify uses the merge ping and commits the frame', () async {
      expect(await out.identifyFanGroup(2, merge: true), isTrue);
      expect(hubTr.writes, [hex('E0 10 50 02 00 00'), hex('E0 60 00 01')]);
    });

    test('board zones: order, BGR color, batch and mask', () async {
      expect(await out.initBoard(), isTrue);
      expect(ite.sent, [hex('CC 60'), hex('CC 32 01'), hex('CC 34 01')]);

      ite.sent.clear();
      expect(await out.sendChassis(leds(47)), isTrue);
      expect([for (final p in ite.sent) p[1]], [0x58, 0x58, 0x58]);
      expect(ite.sent[0].sublist(5, 8), [20, 10, 30]); // GRB from (10,20,30)

      ite.sent.clear();
      expect(
        await out.sendBoardColors(const [
          Rgb(1, 2, 3),
          Rgb(4, 5, 6),
          Rgb(7, 8, 9),
        ]),
        isTrue,
      );
      expect([for (final p in ite.sent) p[1]], [0x20, 0x22, 0x23, 0x28]);
      expect(ite.sent[0].sublist(0x0E, 0x11), [3, 2, 1]);
      expect(ite.sent[1].sublist(0x0E, 0x11), [6, 5, 4]);
      expect(ite.sent[2].sublist(0x0E, 0x11), [9, 8, 7]);
      expect(ite.sent[3], hex('CC 28 FF'));

      ite.sent.clear();
      expect(
        await out.setBoardZones({
          0x20: const BoardZoneConfig(mode: BoardEffectMode.flash),
          0x23: const BoardZoneConfig(
            mode: BoardEffectMode.wave,
            color: Rgb(0, 0, 255),
          ),
        }),
        isTrue,
      );
      // Zones are converted to 0..6 (0x20 -> 0, 0x23 -> 3).
      expect([for (final p in ite.sent) p[1]], [0x20, 0x23, 0x28]);
      expect(ite.sent[2], hex('CC 28 09'));
      expect(ite.sent[1].sublist(2 + 12, 2 + 15), [255, 0, 0]);
    });

    test('RAM: direct colors, safe off on both sticks, blocked slot', () async {
      expect(await out.sendRam(0, leds(12)), isTrue);
      expect(
        [
          for (final w in fury.writes)
            if (w.$2 == 0x50) w,
        ].single,
        (0x61, 0x50, 10),
      );
      expect(fury.writes.where((w) => w.$2 == 0x51).single.$3, 20);
      expect(fury.writes.where((w) => w.$2 == 0x52).single.$3, 30);
      expect(out.blockedReason(LightDeviceId.ram1), isNull);
      expect(out.blockedReason(LightDeviceId.chassis), isNull);

      fury.writes.clear();
      expect(await out.turnRamOff(), isTrue);
      expect(
        {
          for (final w in fury.writes)
            if (w.$2 == 0x31) w.$1,
        },
        {0x61, 0x63},
      );
      expect(
        fury.writes
            .where((w) => w.$2 >= 0x31 && w.$2 <= 0x33)
            .every((w) => w.$3 == 0),
        isTrue,
      );
    });

    test('guarded RAM address is reported and never written', () async {
      final bus = _FuryBus()
        ..dd = 0x72
        ..ddAddress = 0x61;
      final guarded = DeviceLightOutputs(
        Alv2HubProxy.local(
          Alv2Hub.withTransport(
            _HubTransport(),
            delay: (_) async {},
            sleeper: (_) {},
          ),
        ),
        io: LocalLightIo(
          LightIoCore(
            ite: IteController(() => ite, pause: (_) {}, delay: (_) async {}),
            fury: FuryController(open: () => bus),
          ),
        ),
      );
      addTearDown(guarded.close);

      expect(await guarded.sendRam(0, leds(12)), isFalse);
      expect(bus.writes, isEmpty);
      expect(guarded.blockedReason(LightDeviceId.ram1), contains('PWM'));
      expect(guarded.blockedReason(LightDeviceId.ram2), isNull);

      // The other slot is still usable.
      expect(await guarded.sendRam(1, leds(12)), isTrue);
      expect(bus.writes.any((w) => w.$1 == 0x63), isTrue);
    });

    test('driver exceptions become false and do not escape', () async {
      expect(await out.initBoard(), isTrue);
      ite.failNext = true;
      expect(await out.sendChassis(leds(47)), isFalse);

      // The hub loses the transport on the first failure; later sends return
      // false without throwing.
      final failing = DeviceLightOutputs(
        Alv2HubProxy.local(
          Alv2Hub.withTransport(
            _HubTransport()..failNext = true,
            delay: (_) async {},
            sleeper: (_) {},
          ),
        ),
        io: LocalLightIo(
          LightIoCore(
            ite: IteController(() => ite, pause: (_) {}, delay: (_) async {}),
            fury: FuryController(open: () => fury),
          ),
        ),
      );
      addTearDown(failing.close);
      expect(failing.initFans([0, 1, 1, 1]), completion(isFalse));
      expect(failing.turnFanGroupOff(1), completion(isFalse));
      expect(await failing.sendRam(0, leds(12)), isTrue);
    });
  });

  late Directory tmp;
  late ConfigStore store;
  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('lumivent-lighting-');
    store = await ConfigStore.open(tmp);
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  test('repository reads and writes the lighting section', () async {
    final repo = LightingModule.repository(store);
    expect(repo.load(), LightingConfig());
    await repo.save(LightingConfig(argbOff: true, brightness: 0.5));
    expect(store.section('lighting')['argbOff'], isTrue);
    final reloaded = LightingModule.repository(await ConfigStore.open(tmp))
        .load();
    expect(reloaded.argbOff, isTrue);
    expect(reloaded.brightness, 0.5);
  });

  test('repository still reads the old {argbOff} section', () async {
    await store.saveSection('lighting', {'argbOff': true});
    final config = LightingModule.repository(store).load();
    expect(config.argbOff, isTrue);
    expect(config, LightingConfig(argbOff: true));
  });

  test('turning ARGB off saves state and notifies the engine once', () async {
    final engine = FakeEngine();
    final container = ProviderContainer(
      overrides: [
        engineProvider.overrideWithValue(engine),
        ...LightingModule.overrides(store),
      ],
    );
    addTearDown(container.dispose);

    final ctrl = container.read(lightingProvider.notifier);
    ctrl.setArgbOff(true);
    ctrl.setArgbOff(true);
    await store.flush();

    expect(container.read(lightingProvider).argbOff, isTrue);
    expect(engine.sent.whereType<SetArgbOff>().map((c) => c.off), [true]);
    expect(store.section('lighting')['argbOff'], isTrue);
  });

  test('config changes go to the engine and are saved debounced', () async {
    final engine = FakeEngine();
    final container = ProviderContainer(
      overrides: [
        engineProvider.overrideWithValue(engine),
        ...LightingModule.overrides(store),
      ],
    );
    addTearDown(container.dispose);

    final ctrl = container.read(lightingProvider.notifier);
    ctrl.update((c) => c.copyWith(brightness: 0.4));
    ctrl.update((c) => c.copyWith(brightness: 0.4));
    ctrl.identify(2);

    expect(engine.sent.whereType<SetLightingConfig>(), hasLength(1));
    expect(engine.sent.whereType<IdentifyFanGroup>().single.group, 2);
    await Future<void>.delayed(
      LightingController.saveDelay + const Duration(milliseconds: 100),
    );
    await store.flush();
    expect(store.section('lighting')['brightness'], 0.4);
  });
}
