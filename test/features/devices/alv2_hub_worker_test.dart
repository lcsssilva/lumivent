import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/devices/infrastructure/drivers/alv2/hub.dart';
import 'package:lumivent/features/devices/infrastructure/drivers/alv2/hub_worker.dart';
import 'package:lumivent/features/devices/infrastructure/drivers/alv2/lighting.dart';
import 'package:lumivent/features/devices/infrastructure/drivers/alv2/protocol.dart';

class _Clock {
  DateTime t = DateTime(2026);
  DateTime now() => t;
  void sleep(Duration d) => t = t.add(d);
  Future<void> delay(Duration d) async {
    await Future<void>.value();
    t = t.add(d);
  }
}

/// Records packets and the close, in order.
class _Transport implements Alv2Transport {
  _Transport(this.clock);
  final _Clock clock;
  final log = <String>[];
  final times = <DateTime>[];
  Uint8List? input;

  void _add(String s) {
    log.add(s);
    times.add(clock.t);
  }

  String _hex(List<int> d) =>
      d.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');

  @override
  void sendFeature(List<int> data, int length) => _add('F ${_hex(data)}');
  @override
  void write(List<int> data, int length) =>
      _add('O ${_hex(data).substring(0, 8)}');
  @override
  Uint8List getInput(int reportId, int length) => input ?? Uint8List(length);
  @override
  void close() => _add('close');
}

(Alv2HubProxy, _Transport, _Clock) _proxy() {
  final clock = _Clock();
  final tr = _Transport(clock);
  final hub = Alv2Hub.withTransport(
    tr,
    now: clock.now,
    sleeper: clock.sleep,
    delay: clock.delay,
  );
  return (Alv2HubProxy.local(hub), tr, clock);
}

void main() {
  group('Alv2HubCore (no isolate)', () {
    test('answers every command and never throws', () async {
      final clock = _Clock();
      final tr = _Transport(clock);
      final core = Alv2HubCore(
        Alv2Hub.withTransport(
          tr,
          now: clock.now,
          sleeper: clock.sleep,
          delay: clock.delay,
        ),
      );
      expect((await core.handle(1, const HubSetDuty(0, 50))).ok, isTrue);
      expect((await core.handle(2, const HubSetDuty(9, 50))).ok, isFalse);
      expect((await core.handle(3, const HubSetQuantity(0, 7))).ok, isFalse);
      final rpm = await core.handle(4, const HubReadRpm());
      expect(rpm.id, 4);
      expect(rpm.rpm, isNull, reason: 'blank report is not a valid answer');
      expect((await core.handle(5, const HubDispose())).ok, isTrue);
      expect(tr.log.last, 'close');
      expect((await core.handle(6, const HubSetDuty(0, 50))).ok, isFalse);
    });
  });

  group('Alv2HubProxy', () {
    test('control calls keep their order and the 20 ms pause', () async {
      final (hub, tr, _) = _proxy();
      final results = await Future.wait([
        hub.setQuantity(3, 1),
        hub.setMergeOrder([0, 1, 2, 3]),
        hub.disableArgbSync(),
        hub.setDuty(0, 50),
      ]);
      expect(results, everyElement(isTrue));
      expect(tr.log.map((e) => e.substring(0, 11)).toList(), [
        'F e0 10 60 ',
        'F e0 10 63 ',
        'F e0 10 61 ',
        'F e0 20 00 ',
      ]);
      for (var i = 1; i < tr.times.length; i++) {
        expect(tr.times[i].difference(tr.times[i - 1]), alv2PacketGap);
      }
    });

    test('invalid arguments are refused by the hub, not sent', () async {
      final (hub, tr, _) = _proxy();
      expect(await hub.setDuty(9, 50), isFalse);
      expect(await hub.setMotherboardSync([true]), isFalse);
      expect(await hub.setMergeOrder([0, 1]), isFalse);
      expect(tr.log, isEmpty);
    });

    test('readRpm parses the report', () async {
      final (hub, tr, _) = _proxy();
      tr.input = Uint8List(alv2InputLength)
        ..setRange(0, 10, [0xE0, 0xF0, 0, 0, 0x03, 0xED, 0x04, 0xCE, 4, 0xCE]);
      expect(await hub.readRpm(), [0, 1005, 1230, 1230]);
    });

    test(
      'lighting then canvas stay in order; duty waits the remainder',
      () async {
        final (hub, tr, _) = _proxy();
        final a = hub.sendLighting([const Alv2PortWrite(port: 0, mode: 1)]);
        final b = hub.streamCanvas(alv2CanvasWrites(0, 1, List.filled(60, 9)));
        final c = hub.setDuty(0, 50);
        expect(await Future.wait([a, b, c]), everyElement(isTrue));
        expect(
          tr.log.indexWhere((e) => e.startsWith('F e0 10 00')),
          lessThan(tr.log.indexOf('F e0 60 00 01')),
        );
        expect(tr.log.where((e) => e.startsWith('F e0 60')), hasLength(1));
        expect(tr.log.any((e) => e.startsWith('O e0 31')), isTrue);
      },
    );

    test(
      'priority send overtakes the queue and drops what was queued',
      () async {
        final (hub, tr, _) = _proxy();
        final identify = hub.identify(0);
        final off = hub.sendLighting(alv2OffWrites(), priority: true);
        expect(await off, isTrue);
        expect(await identify, isFalse);
        // Only the off sequence reached the device: no ping or second frame.
        expect(tr.log.where((e) => e.startsWith('F e0 60')), hasLength(1));
        expect(tr.log.where((e) => e.startsWith('F e0 10 50')), isEmpty);
      },
    );

    test(
      'dispose closes the hidraw only after the commands sent before it',
      () async {
        final (hub, tr, _) = _proxy();
        final duty = [for (var g = 0; g < 4; g++) hub.setDuty(g, 60)];
        await hub.dispose();
        expect(await Future.wait(duty), everyElement(isTrue));
        expect(tr.log, hasLength(5));
        expect(tr.log.take(4), everyElement(startsWith('F e0 2')));
        expect(tr.log.last, 'close');
        expect(await hub.setDuty(0, 50), isFalse);
        expect(await hub.readRpm(), isNull);
        await hub.dispose(); // second call is a no-op
        expect(tr.log.where((e) => e == 'close'), hasLength(1));
      },
    );
  });
}
