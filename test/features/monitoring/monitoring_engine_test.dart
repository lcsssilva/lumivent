import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/core/engine/engine_host.dart';
import 'package:lumivent/features/monitoring/monitoring.dart';

import 'package:lumivent/features/devices/infrastructure/drivers/alv2/hub.dart';
import 'package:lumivent/features/devices/infrastructure/drivers/alv2/hub_worker.dart';
import 'package:lumivent/features/monitoring/infrastructure/alv2_rpm_source.dart';

import '../../fakes.dart';
import 'smart_fixture.dart';

class FakeSource implements SensorSource {
  int reads = 0;
  bool disposed = false;
  bool fail = false;

  @override
  Map<String, double> read() {
    if (fail) throw StateError('sumiu');
    return {'x': (++reads).toDouble()};
  }

  @override
  void dispose() => disposed = true;
}

class FakeSsds implements SsdReader {
  int reads = 0;

  /// The helper "appears" from this read on.
  int smartFrom = 1;

  @override
  Future<List<SsdInfo>> read() async {
    reads++;
    return [
      SsdInfo(
        controller: 'nvme0',
        model: 'M',
        serial: 'S',
        firmware: 'F',
        smart: reads >= smartFrom ? smartLog() : null,
        smartError: reads >= smartFrom ? null : 'helper is not installed',
      ),
    ];
  }
}

void main() {
  rpmSourceTests();
  test('engine: reads each period, stores history, and reads SSDs', () async {
    final a = FakeSource(), b = FakeSource()..fail = true;
    final ssds = FakeSsds();
    final events = <EngineEvent>[];
    final m = MonitoringEngineModule(
      () => [a, b],
      () => ssds,
      period: const Duration(milliseconds: 10),
      ssdPeriod: const Duration(hours: 1),
    )..start(events.add);
    expect(
      a.reads,
      1,
      reason: 'reads at startup; a failing source does not stop the others',
    );

    await Future<void>.delayed(const Duration(milliseconds: 45));
    final updates = events.whereType<SensorsUpdated>().toList();
    expect(updates.length, greaterThanOrEqualTo(3));
    expect(updates.map((e) => e.sample['x']), [
      for (var i = 1; i <= updates.length; i++) i.toDouble(),
    ]);
    expect(
      events.whereType<SsdsUpdated>().single.ssds.single.controller,
      'nvme0',
    );

    expect(m.handle(const RequestSensorHistory()), isTrue);
    expect(
      events.whereType<SensorHistoryReplay>().single.samples,
      hasLength(updates.length),
    );

    expect(
      ssds.reads,
      1,
      reason: 'with complete SMART, reads again only after ssdPeriod',
    );
    expect(m.handle(const ShutdownEngine()), isFalse);

    m.stop();
    expect(a.disposed && b.disposed, isTrue);
  });

  test('engine: retries quickly without SMART and returns to the long cycle with SMART', () async {
    final ssds = FakeSsds()..smartFrom = 3;
    final events = <EngineEvent>[];
    final m = MonitoringEngineModule(
      () => [],
      () => ssds,
      period: const Duration(hours: 1),
      ssdPeriod: const Duration(hours: 1),
      ssdRetry: const Duration(milliseconds: 10),
    )..start(events.add);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(
      ssds.reads,
      3,
      reason: 'two reads without SMART, then waits ssdPeriod',
    );
    expect(events.whereType<SsdsUpdated>().last.ssds.single.smart, isNotNull);
    m.stop();
  });

  test('controller: requests history, receives the replay, and accumulates readings', () async {
    final engine = FakeEngine();
    final c = ProviderContainer(
      overrides: [engineProvider.overrideWithValue(engine)],
    );
    addTearDown(c.dispose);
    SensorSample s(double x) =>
        SensorSample(DateTime(2026), {Metrics.cpuTctl: x});

    expect(c.read(monitoringProvider).latest, isNull);
    expect(engine.sent.whereType<RequestSensorHistory>(), hasLength(1));

    engine.emit(SensorHistoryReplay([s(1), s(2)]));
    engine.emit(SensorsUpdated(s(3)));
    await Future<void>.delayed(Duration.zero);
    expect(c.read(monitoringProvider).history.series(Metrics.cpuTctl), [
      1,
      2,
      3,
    ]);

    engine.emit(SsdsUpdated(const [], DateTime(2026)));
    await Future<void>.delayed(Duration.zero);
    expect(c.read(monitoringProvider).ssds, isEmpty);
  });
}

/// Hub transport whose RPM replies follow [readings] (one per read), for the
/// alternating readings seen while the lighting streams (2026-10-19).
class _SeqRpmTransport extends _RpmTransport {
  _SeqRpmTransport(this.readings);
  final List<List<int>> readings;
  int _i = 0;

  @override
  Uint8List getInput(int reportId, int length) {
    final r = readings[_i++ % readings.length];
    return Uint8List(length)..setRange(0, 10, [
      0xE0,
      0xF0,
      for (final v in r) ...[v >> 8, v & 0xFF],
    ]);
  }
}

class _RpmTransport implements Alv2Transport {
  final log = <String>[];
  Completer<void>? gate;

  @override
  void sendFeature(List<int> data, int length) => log.add('feature');
  @override
  void write(List<int> data, int length) {}
  @override
  Uint8List getInput(int reportId, int length) =>
      Uint8List(length)
        ..setRange(0, 10, [0xE0, 0xF0, 0, 0, 0x03, 0xED, 0x04, 0xCE, 4, 0xCE]);
  @override
  void close() => log.add('close');
}

void rpmSourceTests() {
  group('Alv2RpmSource', () {
    test('read returns the last reading and never waits for the hub', () async {
      final tr = _RpmTransport();
      final hub = Alv2HubProxy.local(
        Alv2Hub.withTransport(tr, sleeper: (_) {}, delay: (_) async {}),
      );
      final source = Alv2RpmSource(hub);
      expect(source.read(), isEmpty, reason: 'first sample: nothing yet');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(source.read()[Metrics.alv2Rpm(1)], 1005);
      await source.dispose();
      expect(tr.log.last, 'close');
    });

    test(
      'alternating readings under USB load average to the real speed',
      () async {
        final tr = _SeqRpmTransport([
          [0, 885, 1080, 1080],
          [0, 1095, 1350, 1365],
        ]);
        final hub = Alv2HubProxy.local(
          Alv2Hub.withTransport(tr, sleeper: (_) {}, delay: (_) async {}),
        );
        final source = Alv2RpmSource(hub);
        final shown = <double>[];
        for (var i = 0; i < 8; i++) {
          source.read();
          await Future<void>.delayed(const Duration(milliseconds: 5));
          final v = source.read()[Metrics.alv2Rpm(1)];
          if (v != null && i >= Alv2RpmSource.window) shown.add(v);
        }
        // Once the history is full, the shown value stays at the mean (990).
        expect(shown, everyElement(990));
        await source.dispose();
      },
    );
  });
}
