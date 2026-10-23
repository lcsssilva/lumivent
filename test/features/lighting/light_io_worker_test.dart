import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/devices/infrastructure/drivers/alv2/alv2_hub.dart';
import 'package:lumivent/features/devices/infrastructure/drivers/alv2/alv2_hub_proxy.dart';
import 'package:lumivent/features/devices/infrastructure/drivers/ite5702/ite_controller.dart';
import 'package:lumivent/features/devices/infrastructure/drivers/kingston_fury/fury_controller.dart';
import 'package:lumivent/features/lighting/domain/config/lighting_config.dart';
import 'package:lumivent/features/lighting/domain/hardware_mode/gpu_hardware_config.dart';
import 'package:lumivent/features/lighting/domain/config/board_zone_config.dart';
import 'package:lumivent/features/lighting/domain/rgb.dart';
import 'package:lumivent/features/lighting/infrastructure/light_io/device_light_outputs.dart';
import 'package:lumivent/features/lighting/infrastructure/light_io/light_io_command.dart';
import 'package:lumivent/features/lighting/infrastructure/light_io/light_io_reply.dart';
import 'package:lumivent/features/lighting/infrastructure/light_io/light_io_core.dart';

import 'io_worker_fury_bus.dart';
import 'io_worker_ite_transport.dart';
import 'io_worker_no_hub.dart';
import 'recording_io.dart';

Uint8List rgb(int n, [int v = 7]) => Uint8List.fromList(List.filled(n * 3, v));

void main() {
  late IoWorkerIteTransport ite;
  late IoWorkerFuryBus bus;
  late Completer<void> gate;
  late LightIoCore core;
  var next = 0;

  setUp(() {
    ite = IoWorkerIteTransport();
    bus = IoWorkerFuryBus();
    gate = Completer<void>();
    core = LightIoCore(
      // The zone-effect wait is the only async step: it holds the worker.
      ite: IteController(
        () => ite,
        pause: (_) {},
        delay: (d) =>
            d.inMilliseconds == 100 ? gate.future : Future<void>.value(),
      ),
      fury: FuryController(open: () => bus, pause: (_) {}),
    );
  });

  Future<LightIoReply> send(LightIoCommand c) => core.handle(next++, c);

  test('commands run in arrival order and report ok with a duration', () async {
    final init = send(const IoInitBoard());
    final chassis = send(IoChassis(rgb(47)));
    final ram = send(IoRam(0, rgb(12)));
    final replies = await Future.wait([init, chassis, ram]);
    expect(replies.map((r) => r.ok), [true, true, true]);
    expect(replies.every((r) => r.micros >= 0 && !r.dropped), isTrue);
    // init (`CC 60`, `CC 32`, `CC 34`) before the first case stream (`CC 58`).
    expect(ite.sent.first, [0xCC, 0x60]);
    expect(ite.sent.map((p) => p[1]), contains(0x58));
    expect(bus.writes.any((w) => w.$1 == 0x61), isTrue);
  });

  test(
    'a priority off drops the frames still waiting behind a batch',
    () async {
      await send(const IoInitBoard());
      // Holds the worker (100 ms wait of the zone effects) ...
      final zones = send(IoZoneEffects({0x20: const BoardZoneConfig()}));
      // ... frames queue up behind it ...
      final c1 = send(IoChassis(rgb(47, 1)));
      final c2 = send(IoBoardColors(rgb(3, 2)));
      final r1 = send(IoRam(0, rgb(12, 3)));
      // ... and the off overtakes them.
      final off = send(const IoBoardOff());
      final ramOff = send(const IoRamOff());
      // A frame sent after the off is not dropped.
      final after = send(IoChassis(rgb(47, 9)));
      ite.sent.clear();
      bus.writes.clear();
      gate.complete();

      expect((await zones).ok, isTrue);
      for (final r in await Future.wait([c1, c2, r1])) {
        expect(r.ok, isFalse);
        expect(r.dropped, isTrue);
      }
      expect((await off).ok, isTrue);
      expect((await ramOff).ok, isTrue);
      expect((await after).ok, isTrue);
      // Nothing of the dropped frames was written; the off was.
      // Direct-mode data (0x50..) is never written, the black single color is.
      expect(bus.writes.where((w) => w.$2 == 0x50), isEmpty);
      expect(bus.writes.where((w) => w.$2 == 0x31), isNotEmpty);
      final cmds = ite.sent.map((p) => p[1]).toList();
      expect(cmds.indexOf(0x28), lessThan(cmds.indexOf(0x58)));
    },
  );

  test('RAM replies carry the disabled reason of each slot', () async {
    bus
      ..dd = 0x72
      ..guarded = 0x61;
    final r = await send(IoRam(0, rgb(12)));
    expect(r.ok, isFalse);
    expect(r.ramReasons![0], contains('PWM'));
    expect(r.ramReasons![1], isNull);
    expect(bus.writes, isEmpty);
    expect((await send(IoChassis(rgb(47)))).ramReasons, isNull);
  });

  test('driver exceptions become ok=false and keep the worker alive', () async {
    await send(const IoInitBoard());
    final bad = await send(IoRam(0, Uint8List(5))); // wrong size
    expect(bad.ok, isFalse);
    expect((await send(IoRam(0, rgb(12)))).ok, isTrue);
  });

  test('close shuts both drivers and nothing runs after it', () async {
    await send(const IoInitBoard());
    await send(IoRam(0, rgb(12)));
    expect((await send(const IoClose())).ok, isTrue);
    expect(ite.closed, isTrue);
    expect(bus.closed, isTrue);
    ite.sent.clear();
    bus.writes.clear();
    expect((await send(IoChassis(rgb(47)))).ok, isFalse);
    expect((await send(const IoRamOff())).ok, isFalse);
    expect(ite.sent, isEmpty);
    expect(bus.writes, isEmpty);
  });

  group('adapter', () {
    late RecordingIo io;
    late DeviceLightOutputs out;
    setUp(() {
      io = RecordingIo();
      out = DeviceLightOutputs(
        Alv2HubProxy.local(
          Alv2Hub.withTransport(
            IoWorkerNoHub(),
            delay: (_) async {},
            sleeper: (_) {},
          ),
        ),
        io: io,
      );
    });

    test('colors travel as bytes and offs as their own commands', () async {
      await out.sendChassis([const Rgb(1, 2, 3), const Rgb(4, 5, 6)]);
      await out.turnBoardOff();
      await out.turnRamOff();
      expect(io.commands[0], isA<IoChassis>());
      expect((io.commands[0] as IoChassis).rgb, [1, 2, 3, 4, 5, 6]);
      expect(io.commands[1], isA<IoBoardOff>());
      expect(io.commands[2], isA<IoRamOff>());
    });

    test(
      'GPU commands carry color, brightness and the hardware config',
      () async {
        await out.initGpu();
        await out.sendGpuColor(const Rgb(1, 2, 3), brightness: 4);
        const hw = GpuHardwareConfig(
          effect: GpuEffect.pulse,
          speed: 6,
          brightness: 7,
          color: Rgb(8, 9, 10),
        );
        await out.setGpuHardware(hw);
        await out.turnGpuOff();
        expect(io.commands[0], isA<IoInitGpu>());
        final color = io.commands[1] as IoGpuStatic;
        expect((color.r, color.g, color.b, color.brightness), (1, 2, 3, 4));
        expect((io.commands[2] as IoGpuEffect).config, hw);
        expect(io.commands[3], isA<IoGpuOff>());
      },
    );

    test('close stops the worker in order and refuses later writes', () async {
      await out.sendRam(0, [const Rgb(1, 1, 1)]);
      unawaited(out.close());
      unawaited(out.close());
      expect(await out.sendRam(0, [const Rgb(1, 1, 1)]), isFalse);
      expect(await out.turnBoardOff(), isFalse);
      out.invalidate();
      await Future<void>.delayed(Duration.zero);
      expect(io.commands.whereType<IoClose>(), hasLength(1));
      expect(io.commands.last, isA<IoClose>());
      expect(io.disposed, isTrue);
    });
  });
}
