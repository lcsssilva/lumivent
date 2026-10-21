import 'dart:async';

import 'package:lumivent/core/engine/engine_host.dart';

class FakeEngine implements EngineApi {
  final sent = <EngineCommand>[];
  final _events = StreamController<EngineEvent>.broadcast();
  final _last = <Type, EngineEvent>{};

  @override
  Stream<EngineEvent> get events => _events.stream;

  @override
  T? lastEvent<T extends EngineEvent>() => _last[T] as T?;

  void emit(EngineEvent e) {
    _last[e.runtimeType] = e;
    _events.add(e);
  }

  @override
  void send(EngineCommand command) => sent.add(command);

  @override
  Future<void> shutdown() async {}
}
