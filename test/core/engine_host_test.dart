import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/core/engine/isolate_engine.dart';
import 'package:lumivent/core/engine/engine_event.dart';
import 'package:lumivent/core/engine/engine_stopped.dart';
import 'package:lumivent/core/engine/engine_module.dart';
import 'package:lumivent/core/engine/engine_startup_exception.dart';

import 'ping.dart';
import 'pong.dart';
import 'started.dart';
import 'stopping.dart';
import 'boom.dart';
import 'echo_module.dart';
import 'faulty_module.dart';
import 'throwing_start_module.dart';

// Runs inside the engine isolate.
List<EngineModule> _modules(int base) => [EchoModule(base)];

List<EngineModule> _throwingStartModules(int base) => [
  EchoModule(base),
  ThrowingStartModule(),
];

List<EngineModule> _throwingBuild(int base) => throw StateError('build boom');

List<EngineModule> _throwingHandleModules(int base) => [
  FaultyModule(),
  EchoModule(base),
];

List<EngineModule> _throwingStopModules(int base) => [
  EchoModule(base),
  FaultyModule(throwOnStop: true),
];

void main() {
  test('real isolate: modules start, respond, and stop in order', () async {
    final engine = await IsolateEngine.spawn(_modules, 100);
    final received = <EngineEvent>[];
    final sub = engine.events.listen(received.add);

    final pong = engine.events.firstWhere((e) => e is Pong);
    engine.send(const Ping(1));
    expect((await pong as Pong).n, 101);
    expect(engine.lastEvent<Started>()?.base, 100);
    expect(engine.lastEvent<Pong>()?.n, 101);

    await engine.shutdown();
    await sub.cancel();
    expect(received.whereType<Stopping>(), hasLength(1));
    expect(received.last, isA<EngineStopped>());
  });

  test(
    'real isolate: a module that throws on handle does not stop the loop',
    () async {
      final engine = await IsolateEngine.spawn(_throwingHandleModules, 100);
      final pong = engine.events.firstWhere((e) => e is Pong);
      engine.send(const Boom());
      engine.send(const Ping(1));
      expect((await pong as Pong).n, 101);
      await engine.shutdown();
    },
  );

  test(
    'real isolate: a module that throws on stop does not block the others',
    () async {
      final engine = await IsolateEngine.spawn(_throwingStopModules, 100);
      final received = <EngineEvent>[];
      final sub = engine.events.listen(received.add);
      await engine.shutdown();
      await sub.cancel();
      expect(received.whereType<Stopping>(), hasLength(1));
      expect(received.last, isA<EngineStopped>());
    },
  );

  test('real isolate: a module that throws on start fails the spawn', () async {
    await expectLater(
      IsolateEngine.spawn(_throwingStartModules, 100),
      throwsA(
        isA<EngineStartupException>().having(
          (e) => e.message,
          'message',
          contains('start boom'),
        ),
      ),
    );
  });

  test('real isolate: a factory that throws fails the spawn', () async {
    await expectLater(
      IsolateEngine.spawn(_throwingBuild, 100),
      throwsA(
        isA<EngineStartupException>().having(
          (e) => e.message,
          'message',
          contains('build boom'),
        ),
      ),
    );
  });
}
