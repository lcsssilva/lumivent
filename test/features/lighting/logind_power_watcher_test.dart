import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/lighting/infrastructure/logind_power_watcher.dart';
import 'package:lumivent/features/lighting/infrastructure/inhibitor_lock.dart';

import 'fake_inhibitor_lock.dart';
import 'fake_logind_bus.dart';

void main() {
  late FakeLogindBus bus;
  late LogindPowerWatcher w;
  late List<String> log;

  Future<void> startWith({
    Future<void> Function()? sleep,
    Future<void> Function()? shutdown,
    void Function()? resume,
  }) => w.start(
    beforeSleep: sleep ?? () async => log.add('sleep'),
    afterResume: resume ?? () => log.add('resume'),
    beforeShutdown: shutdown ?? () async => log.add('shutdown'),
  );

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  setUp(() {
    bus = FakeLogindBus();
    log = [];
    w = LogindPowerWatcher(
      busFactory: () => bus,
      callbackTimeout: const Duration(milliseconds: 100),
    );
  });

  test('start acquires an inhibitor', () async {
    await startWith();
    expect(bus.locks, hasLength(1));
    expect(w.hasInhibitor, isTrue);
  });

  test('suspend: callback and release inhibitor; resume: callback and new inhibitor', () async {
    await startWith();
    bus.sleep.add(true);
    await settle();
    expect(log, ['sleep']);
    expect(bus.locks[0].released, isTrue);
    expect(w.hasInhibitor, isFalse);

    bus.sleep.add(false);
    await settle();
    expect(log, ['sleep', 'resume']);
    expect(bus.locks, hasLength(2));
    expect(bus.locks[1].released, isFalse);
  });

  test('repeated signals do not repeat callbacks or inhibitors', () async {
    await startWith();
    bus.sleep
      ..add(true)
      ..add(true);
    await settle();
    bus.sleep
      ..add(false)
      ..add(false);
    await settle();
    expect(log, ['sleep', 'resume']);
    expect(bus.locks, hasLength(2));
  });

  test(
    'the inhibitor is released only after the slow callback finishes',
    () async {
      final gate = Completer<void>();
      await startWith(sleep: () => gate.future);
      bus.sleep.add(true);
      await settle();
      expect(bus.locks[0].released, isFalse);
      gate.complete();
      await settle();
      expect(bus.locks[0].released, isTrue);
    },
  );

  test(
    'stalled callback exceeds the timeout and the inhibitor is released',
    () async {
      await startWith(sleep: () => Completer<void>().future);
      bus.sleep.add(true);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(bus.locks[0].released, isTrue);
    },
  );

  test('throwing callback does not prevent inhibitor release', () async {
    await startWith(sleep: () async => throw StateError('x'));
    bus.sleep.add(true);
    await settle();
    expect(bus.locks[0].released, isTrue);
  });

  test(
    'shutdown: callback once and release, without a new inhibitor',
    () async {
      await startWith();
      bus.shutdown
        ..add(true)
        ..add(true);
      await settle();
      expect(log, ['shutdown']);
      expect(bus.locks[0].released, isTrue);
      bus.sleep.add(true);
      bus.sleep.add(false);
      await settle();
      expect(bus.locks, hasLength(1));
    },
  );

  test('failed Inhibit does not crash; signals still call callbacks', () async {
    bus.failInhibit = true;
    await startWith();
    expect(w.hasInhibitor, isFalse);
    bus.sleep.add(true);
    await settle();
    expect(log, ['sleep']);
  });

  test('without system bus: start does not throw', () async {
    w = LogindPowerWatcher(busFactory: () => throw StateError('sem bus'));
    await startWith();
    await w.stop();
  });

  test(
    'stop releases the inhibitor, closes the bus, and ignores later signals',
    () async {
      await startWith();
      await w.stop();
      expect(bus.locks[0].released, isTrue);
      expect(bus.closed, isTrue);
      bus.sleep.add(true);
      await settle();
      expect(log, isEmpty);
    },
  );

  test(
    'cancelled shutdown: callbacks again later, resume and new inhibitor',
    () async {
      await startWith();
      bus.shutdown.add(true);
      await settle();
      expect(log, ['shutdown']);
      expect(w.hasInhibitor, isFalse);

      bus.shutdown.add(false);
      await settle();
      expect(log, ['shutdown', 'resume']);
      expect(bus.locks, hasLength(2));
      expect(w.hasInhibitor, isTrue);

      // A later shutdown (or sleep) works again.
      bus.shutdown.add(true);
      await settle();
      expect(log, ['shutdown', 'resume', 'shutdown']);
      expect(bus.locks[1].released, isTrue);
    },
  );

  test(
    'PrepareForShutdown(false) without a previous true is ignored',
    () async {
      await startWith();
      bus.shutdown.add(false);
      await settle();
      expect(log, isEmpty);
      expect(bus.locks, hasLength(1));
    },
  );

  test('a throwing afterResume does not prevent the new inhibitor', () async {
    await startWith(resume: () => throw StateError('resume failed'));
    bus.sleep.add(true);
    await settle();
    bus.sleep.add(false);
    await settle();
    expect(bus.locks, hasLength(2));
    expect(w.hasInhibitor, isTrue);

    bus.shutdown.add(true);
    await settle();
    bus.shutdown.add(false);
    await settle();
    expect(bus.locks, hasLength(3));
    expect(w.hasInhibitor, isTrue);
  });

  test('a failing release during stop is logged and ignored', () async {
    await startWith();
    bus.locks.single.throwOnRelease = true;
    await w.stop();
    expect(w.hasInhibitor, isFalse);
  });

  test('a failing release after suspend leaves no inhibitor', () async {
    await startWith();
    bus.locks.single.throwOnRelease = true;
    bus.sleep.add(true);
    await settle();
    expect(w.hasInhibitor, isFalse);
    expect(bus.locks.single.released, isTrue);
  });

  test('stop while inhibit is pending releases the late lock', () async {
    final hold = Completer<InhibitorLock>();
    bus.holdInhibit = hold;
    final starting = startWith();
    await settle();
    await w.stop();
    final lock = FakeInhibitorLock();
    hold.complete(lock);
    await starting;
    expect(lock.released, isTrue);
    expect(w.hasInhibitor, isFalse);
  });

  test('stop closes the bus even if close throws', () async {
    await startWith();
    bus.throwOnClose = true;
    await w.stop();
    expect(bus.closed, isTrue);
  });
}
