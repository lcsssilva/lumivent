import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/lighting/infrastructure/html_effects/effect_worker_protocol.dart';
import 'package:lumivent/features/lighting/infrastructure/html_effects/shared_effect_worker.dart';

import 'fake_workers.dart';

void main() {
  late FakeWorkers workers;
  setUp(() => workers = FakeWorkers());
  tearDown(() => workers.close());

  test('consecutive effects share one worker', () async {
    final worker = SharedEffectWorker(
      spawn: workers.spawn,
      idleTimeout: const Duration(hours: 1),
    );

    final first = await worker.acquire();
    await first.request(frameRequest(0), timeout: const Duration(seconds: 5));
    first.release();
    final second = await worker.acquire();
    await second.request(frameRequest(0), timeout: const Duration(seconds: 5));

    expect(workers.connections, hasLength(1));
    expect(workers.connections.single.isClosed, isFalse);
  });

  test('a replaced effect can no longer reach the worker', () async {
    final worker = SharedEffectWorker(
      spawn: workers.spawn,
      idleTimeout: const Duration(hours: 1),
    );
    final stale = await worker.acquire();
    final current = await worker.acquire();

    stale.send(propertyRequest('speed', 1));
    current.send(propertyRequest('speed', 2));
    await expectLater(
      stale.request(frameRequest(0), timeout: const Duration(seconds: 5)),
      throwsA(isA<Exception>()),
    );
    // A late release of the replaced effect does not free the worker.
    stale.release();
    await pumpEventQueue();

    expect(stale.isCurrent, isFalse);
    expect(current.isCurrent, isTrue);
    expect(workers.received.single, [EffectWorkerOperation.property.name]);
  });

  test(
    'an idle worker is closed and the next effect starts a new one',
    () async {
      final worker = SharedEffectWorker(
        spawn: workers.spawn,
        idleTimeout: Duration.zero,
      );
      (await worker.acquire()).release();
      await pumpEventQueue();
      expect(workers.connections.single.isClosed, isTrue);

      final next = await worker.acquire();
      expect(next.isCurrent, isTrue);
      expect(workers.connections, hasLength(2));
    },
  );

  test('a worker that died is replaced on the next load', () async {
    final worker = SharedEffectWorker(
      spawn: workers.spawn,
      idleTimeout: const Duration(hours: 1),
    );
    final hung = await worker.acquire();
    // A hung frame kills the worker.
    workers.connections.single.close();
    expect(hung.isCurrent, isFalse);

    final next = await worker.acquire();
    expect(next.isCurrent, isTrue);
    expect(workers.connections, hasLength(2));
  });

  test('a failed spawn is retried by the next load', () async {
    var attempts = 0;
    final worker = SharedEffectWorker(
      spawn: () {
        attempts++;
        if (attempts == 1) return Future.error(StateError('no worker'));
        return workers.spawn();
      },
      idleTimeout: const Duration(hours: 1),
    );
    await expectLater(worker.acquire(), throwsStateError);

    final lease = await worker.acquire();
    expect(lease.isCurrent, isTrue);
    expect(attempts, 2);
  });
}
