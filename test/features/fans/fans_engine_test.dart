import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/core/engine/engine_event.dart';
import 'package:lumivent/core/persistence/config_store.dart';
import 'package:lumivent/features/fans/fans.dart';
import 'package:lumivent/features/fans/infrastructure/metrics_fan_temperatures.dart';
import 'package:lumivent/features/monitoring/monitoring.dart';

import 'fake_driver.dart';
import 'fake_temps.dart';
import 'fake_clock.dart';

const _slow = Duration(hours: 1);
const _quick = Duration(milliseconds: 10);

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 30));

FansEngineModule _module(
  FakeDriver d,
  FakeTemps t,
  FansConfig c, {
  Duration configDelay = _quick,
  FakeClock? clock,
}) => FansEngineModule(
  () => d,
  t,
  c,
  period: _slow,
  configDelay: configDelay,
  now: () => (clock ?? FakeClock(DateTime(2026))).t,
);

/// Advances the clock and sends a config (the same value) to run one loop cycle.
Future<void> _tick(
  FansEngineModule m,
  FansConfig c,
  FakeClock clock,
  Duration dt,
) async {
  clock.advance(dt);
  m.handle(SetFansConfig(c));
  await Future<void>.delayed(const Duration(milliseconds: 40));
}

void main() {
  test('calculates duty from the curve and group source temperature', () async {
    final d = FakeDriver(), t = FakeTemps()..values[FanTempSource.cpuTctl] = 55;
    final events = <EngineEvent>[];
    final cfg = FansConfig.defaults();
    _module(d, t, cfg).start(events.add);
    await _settle();

    // Standard at 55 °C = 62% of maximum; group 1 (140 mm) uses the same percentage.
    expect(d.duties, [for (var g = 0; g < 4; g++) (g, cfg[g].duty(55))]);
    expect(d.duties.first.$2, 62);
    expect(d.syncOffCalls, 1, reason: 'sync desligado na partida');
    final status = events.whereType<FansStatus>().single;
    expect(status.hubOk, isTrue);
    expect(status.groups[0].temp, 55);
    expect(status.groups[0].rawTemp, 55);
    expect(status.groups[0].duty, 62);
  });

  test('group without a source temperature is skipped', () async {
    final d = FakeDriver(), t = FakeTemps()..values[FanTempSource.cpuTctl] = 55;
    var cfg = FansConfig.defaults();
    cfg = cfg.replaced(cfg[1].copyWith(source: FanTempSource.gpuEdge));
    final events = <EngineEvent>[];
    _module(d, t, cfg).start(events.add);
    await _settle();

    expect(d.duties.map((e) => e.$1), [
      0,
      2,
      3,
    ], reason: '1 without GPU temperature');
    final status = events.whereType<FansStatus>().single;
    expect(status.groups[1].temp, isNull);
    expect(status.groups[1].rawTemp, isNull);
    expect(status.groups[1].duty, isNull);
  });

  test('SetFansConfig combines consecutive commands into one cycle', () async {
    final d = FakeDriver(), t = FakeTemps()..values[FanTempSource.cpuTctl] = 55;
    final events = <EngineEvent>[];
    final cfg = FansConfig.defaults();
    final m = _module(d, t, cfg)..start(events.add);
    await _settle();
    d.duties.clear();

    // Fast response: without averaging or ramping, duty goes directly to the target.
    for (final p in [30.0, 40.0, 50.0, 100.0]) {
      final g0 = cfg[0].copyWith(
        preset: FanPreset.fixed,
        fixedPercent: p,
        response: FanResponse.fast,
      );
      final c = cfg.replaced(g0);
      expect(m.handle(SetFansConfig(c)), isTrue);
    }
    expect(d.duties, isEmpty, reason: 'nothing is sent immediately');
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(
      events.whereType<FansStatus>(),
      hasLength(2),
      reason: 'startup + one extra cycle',
    );
    expect(d.duties.where((e) => e.$1 == 0), [
      (0, 100),
    ], reason: 'the last command wins');
    await m.stop();
  });

  test(
    'disables motherboard sync at startup and retries until the hub accepts',
    () async {
      final d = FakeDriver()..ok = false, t = FakeTemps();
      final cfg = FansConfig.defaults();
      final events = <EngineEvent>[];
      final m = _module(d, t, cfg)..start(events.add);
      await _settle();
      expect(d.syncOffCalls, 1);
      expect(events.whereType<FansStatus>().single.hubOk, isFalse);

      d.ok = true;
      m.handle(SetFansConfig(cfg));
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(d.syncOffCalls, 2, reason: 'failed, tries again');
      expect(events.whereType<FansStatus>().last.hubOk, isTrue);

      m.handle(
        SetFansConfig(cfg.replaced(cfg[2].copyWith(preset: FanPreset.full))),
      );
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(
        d.syncOffCalls,
        2,
        reason: 'it already succeeded: never send again',
      );
      await m.stop();
    },
  );

  test(
    'normal response increases duty by at most 15 points per second',
    () async {
      final d = FakeDriver(),
          t = FakeTemps()..values[FanTempSource.cpuTctl] = 40;
      final clock = FakeClock(DateTime(2026));
      final cfg = FansConfig.defaults();
      final m = _module(d, t, cfg, clock: clock)..start((_) {});
      await _settle();
      var prev = d.lastDuty(0);

      t.values[FanTempSource.cpuTctl] = 90;
      for (var i = 1; i <= 8; i++) {
        await _tick(m, cfg, clock, const Duration(seconds: 1));
        final duty = d.lastDuty(0);
        expect(duty, lessThanOrEqualTo(prev + 15), reason: 'passo $i');
        prev = duty;
      }
      // The 4-second average is already 90 °C and the ramp reached the target.
      expect(prev, cfg[0].duty(90));
      await m.stop();
    },
  );

  test('fast response goes directly to the target', () async {
    final d = FakeDriver(), t = FakeTemps()..values[FanTempSource.cpuTctl] = 40;
    final events = <EngineEvent>[];
    final clock = FakeClock(DateTime(2026));
    var cfg = FansConfig.defaults();
    cfg = cfg.replaced(cfg[0].copyWith(response: FanResponse.fast));
    final m = _module(d, t, cfg, clock: clock)..start(events.add);
    await _settle();

    t.values[FanTempSource.cpuTctl] = 90;
    await _tick(m, cfg, clock, const Duration(seconds: 1));
    expect(d.lastDuty(0), cfg[0].duty(90));
    final status = events.whereType<FansStatus>().last.groups[0];
    expect(status.temp, 90);
    expect(status.rawTemp, 90);
    await m.stop();
  });

  test('changing the source resets the average', () async {
    final d = FakeDriver(),
        t = FakeTemps()
          ..values[FanTempSource.cpuTctl] = 40
          ..values[FanTempSource.gpuEdge] = 30;
    final events = <EngineEvent>[];
    final clock = FakeClock(DateTime(2026));
    final cfg = FansConfig.defaults();
    final m = _module(d, t, cfg, clock: clock)..start(events.add);
    await _settle();

    t.values[FanTempSource.cpuTctl] = 90;
    await _tick(m, cfg, clock, const Duration(seconds: 1));
    expect(
      events.whereType<FansStatus>().last.groups[0].temp,
      65,
      reason: 'average of 40 and 90',
    );

    final trocado = cfg.replaced(
      cfg[0].copyWith(source: FanTempSource.gpuEdge),
    );
    clock.advance(const Duration(seconds: 1));
    m.handle(SetFansConfig(trocado));
    await Future<void>.delayed(const Duration(milliseconds: 40));
    final status = events.whereType<FansStatus>().last.groups[0];
    expect(
      status.temp,
      30,
      reason: 'the CPU average does not enter the GPU average',
    );
    expect(status.rawTemp, 30);
    await m.stop();
  });

  test('stop sends each group its own curve at the last temperature', () async {
    final d = FakeDriver(), t = FakeTemps()..values[FanTempSource.cpuTctl] = 55;
    var cfg = FansConfig.defaults();
    cfg = cfg.replaced(
      cfg[0].copyWith(preset: FanPreset.full, startStop: true),
    );
    final m = _module(d, t, cfg)..start((_) {});
    await _settle();
    d.duties.clear();
    t.values[FanTempSource.cpuTctl] = null; // reading lost: use the last value

    await m.stop();
    expect(d.duties, [for (var g = 0; g < 4; g++) (g, cfg[g].exitDuty(55))]);
    expect(d.duties.first.$2, 100); // group 0 on Full
    expect(d.duties[1].$2, 62); // Standard
  });

  test('stop without any temperature uses Standard at 70 °C', () async {
    final d = FakeDriver();
    final cfg = FansConfig.defaults();
    final m = _module(d, FakeTemps(), cfg)..start((_) {});
    await _settle();
    d.duties.clear();
    await m.stop();
    expect(d.duties.first, (0, cfg[0].exitDuty(null)));
    expect(d.duties.first.$2, 75);
  });

  test(
    'cycles never overlap while the hub is slow, and a config is not lost',
    () async {
      final d = FakeDriver()..latency = const Duration(milliseconds: 60);
      final t = FakeTemps()..values[FanTempSource.cpuTctl] = 55;
      final cfg = FansConfig.defaults();
      final m = FansEngineModule(
        () => d,
        t,
        cfg,
        period: const Duration(milliseconds: 15),
        configDelay: _quick,
      )..start((_) {});
      await Future<void>.delayed(const Duration(milliseconds: 400));
      // Ticks every 15 ms but each cycle needs ~120 ms: at most one cycle at a
      // time means at most 4 duties in flight, so the count stays low.
      final perGroup = d.duties.where((e) => e.$1 == 0).length;
      expect(perGroup, lessThanOrEqualTo(5));
      await m.stop();
    },
  );

  test(
    'stop sends the exit duty and returns only after the hub answered',
    () async {
      final d = FakeDriver()..latency = const Duration(milliseconds: 50);
      final t = FakeTemps()..values[FanTempSource.cpuTctl] = 55;
      final m = _module(d, t, FansConfig.defaults())..start((_) {});
      await Future<void>.delayed(const Duration(milliseconds: 250));
      d.duties.clear();
      var done = false;
      final stopping = m.stop().then((_) => done = true);
      expect(d.duties, hasLength(4), reason: 'sent at once');
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(done, isFalse, reason: 'waits for the hub');
      await stopping;
      expect(done, isTrue);
    },
  );

  test('MetricsFanTemperatures maps sources to metrics', () {
    SensorSample? sample = SensorSample(DateTime(2026), {
      Metrics.cpuTctl: 50,
      Metrics.gpuJunction: 60,
      Metrics.gpuEdge: 40,
    });
    final temps = MetricsFanTemperatures(() => sample);
    expect(temps.read(FanTempSource.cpuTctl), 50);
    expect(temps.read(FanTempSource.gpuJunction), 60);
    expect(temps.read(FanTempSource.gpuEdge), 40);
    sample = null;
    expect(temps.read(FanTempSource.cpuTctl), isNull);
  });

  test(
    'MetricsFanTemperatures reads board sources by Metrics.boardTemps IDs',
    () {
      final sample = SensorSample(DateTime(2026), {
        'board.system1': 31,
        'board.pch': 32,
        'board.cpu': 33,
        'board.pciex16': 34,
        'board.vrm': 35,
        'board.pciex4': 36,
        'board.system2': 37,
      });
      final temps = MetricsFanTemperatures(() => sample);
      expect(temps.read(FanTempSource.boardSystem1), 31);
      expect(temps.read(FanTempSource.boardPch), 32);
      expect(temps.read(FanTempSource.boardCpuSocket), 33);
      expect(temps.read(FanTempSource.boardPciex16), 34);
      expect(temps.read(FanTempSource.boardVrm), 35);
      expect(temps.read(FanTempSource.boardPciex4), 36);
      expect(temps.read(FanTempSource.boardSystem2), 37);
    },
  );

  group('repository', () {
    late Directory tmp;
    late ConfigStore store;
    setUp(() async {
      tmp = Directory.systemTemp.createTempSync('lumivent-fans-');
      store = await ConfigStore.open(tmp);
    });
    tearDown(() => tmp.deleteSync(recursive: true));

    test('legacy default names become empty; chosen names are kept', () async {
      await store.saveSection('fans', {
        'groups': [
          {'name': 'Grupo 0'},
          {'name': ' Group 1 '},
          // Another group's default is a name the user chose for this one.
          {'name': 'Grupo 1'},
          {'name': 'Topo'},
        ],
      });
      final c = FansModule.repository(store).load();
      expect(c.groups.map((g) => g.name), ['', '', 'Grupo 1', 'Topo']);
    });

    test('round trip', () async {
      final repo = FansModule.repository(store);
      expect(
        repo.load().groups.map((g) => g.name),
        FansConfig.defaults().groups.map((g) => g.name),
      );
      var cfg = FansConfig.defaults();
      cfg = cfg.replaced(
        cfg[1].copyWith(
          name: 'Frente',
          size: FanSize.mm120,
          preset: FanPreset.user2,
          userPoints: {
            FanPreset.user2: const [FanPoint(30, 40), FanPoint(70, 90)],
          },
          customPoints: const [FanPoint(20.5, 33)],
          fixedPercent: 77,
          startStop: true,
          source: FanTempSource.gpuJunction,
          response: FanResponse.smooth,
        ),
      );
      cfg = cfg.replaced(
        cfg[2].copyWith(
          source: FanTempSource.boardVrm,
          response: FanResponse.fast,
        ),
      );
      cfg = cfg.replaced(cfg[3].copyWith(source: FanTempSource.boardPciex4));
      await repo.save(cfg);
      expect(store.section('fans')['groups'], isA<List<Object?>>());

      final loaded = FansModule.repository(await ConfigStore.open(tmp)).load();
      final g = loaded[1];
      expect(g.name, 'Frente');
      expect(g.size, FanSize.mm120);
      expect(g.preset, FanPreset.user2);
      expect(g.userPoints[FanPreset.user2], const [
        FanPoint(30, 40),
        FanPoint(70, 90),
      ]);
      expect(g.customPoints, const [FanPoint(20.5, 33)]);
      expect(g.fixedPercent, 77);
      expect(g.startStop, isTrue);
      expect(g.source, FanTempSource.gpuJunction);
      expect(g.response, FanResponse.smooth);
      expect(loaded[2].source, FanTempSource.boardVrm);
      expect(loaded[2].response, FanResponse.fast);
      expect(loaded[3].source, FanTempSource.boardPciex4);
      expect(loaded[0].preset, FanPreset.standard);
      expect(loaded[0].response, FanResponse.normal);
    });

    test(
      'old config with mbSync is read without error and the field is ignored',
      () async {
        await store.saveSection('fans', {
          'groups': [
            {
              'name': 'Teto',
              'size': 'mm140',
              'preset': 'quiet',
              'source': 'boardVrm',
              'mbSync': true,
            },
            {'name': 'Frente', 'mbSync': false, 'response': 'fast'},
          ],
        });
        final c = FansModule.repository(store).load();
        expect(c[0].name, 'Teto');
        expect(c[0].preset, FanPreset.quiet);
        expect(c[0].source, FanTempSource.boardVrm);
        expect(
          c[0].response,
          FanResponse.normal,
          reason: 'missing response field uses the default',
        );
        expect(c[1].response, FanResponse.fast);
        expect(c[1].source, FanTempSource.cpuTctl);
      },
    );

    test('invalid JSON falls back to defaults field by field', () async {
      final d = FansConfig.defaults();
      for (final raw in <Object?>[
        null,
        3,
        'x',
        <Object?>[],
        {'a': 1},
      ]) {
        await store.saveSection('fans', {'groups': raw});
        expect(FansModule.repository(store).load()[2].preset, d[2].preset);
      }
      await store.saveSection('fans', {
        'groups': [
          {
            'name': 5,
            'size': 'gigante',
            'preset': 'quiet',
            'customPoints': [
              [1, 2, 3],
            ],
            'userPoints': {'user1': 'nada', 'custom': []},
            'fixedPercent': 'x',
            'startStop': 1,
            'source': 'gpuEdge',
            'response': 'turbo',
          },
          'lixo',
        ],
      });
      final c = FansModule.repository(store).load();
      expect(c[0].name, d[0].name);
      expect(c[0].size, d[0].size);
      expect(c[0].preset, FanPreset.quiet);
      expect(c[0].customPoints, d[0].customPoints);
      expect(c[0].userPoints, isEmpty);
      expect(c[0].fixedPercent, d[0].fixedPercent);
      expect(c[0].startStop, d[0].startStop);
      expect(c[0].source, FanTempSource.gpuEdge);
      expect(
        c[0].response,
        FanResponse.normal,
        reason: 'invalid response falls back to the default',
      );
      expect(c[1].size, d[1].size);
    });
  });
}
