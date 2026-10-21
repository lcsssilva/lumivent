import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/core/engine/engine_host.dart';

class Ping extends EngineCommand {
  const Ping(this.n);
  final int n;
}

class Pong extends EngineEvent {
  const Pong(this.n);
  final int n;
}

class Started extends EngineEvent {
  const Started(this.base);
  final int base;
}

class Stopping extends EngineEvent {
  const Stopping();
}

class _EchoModule implements EngineModule {
  _EchoModule(this.base);
  final int base;
  late void Function(EngineEvent) emit;

  @override
  void start(void Function(EngineEvent) emit) =>
      (this.emit = emit)(Started(base));

  @override
  bool handle(EngineCommand command) {
    if (command is! Ping) return false;
    emit(Pong(command.n + base));
    return true;
  }

  @override
  void stop() => emit(const Stopping());
}

class Boom extends EngineCommand {
  const Boom();
}

/// Throws on [Boom] in handle, and/or in stop when [throwOnStop] is set.
class _FaultyModule implements EngineModule {
  _FaultyModule({this.throwOnStop = false});
  final bool throwOnStop;

  @override
  void start(void Function(EngineEvent) emit) {}

  @override
  bool handle(EngineCommand command) {
    if (command is! Boom) return false;
    throw StateError('handle boom');
  }

  @override
  void stop() {
    if (throwOnStop) throw StateError('stop boom');
  }
}

// Runs inside the engine isolate.
List<EngineModule> _modules(int base) => [_EchoModule(base)];

List<EngineModule> _throwingHandleModules(int base) => [
  _FaultyModule(),
  _EchoModule(base),
];

List<EngineModule> _throwingStopModules(int base) => [
  _EchoModule(base),
  _FaultyModule(throwOnStop: true),
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
}
