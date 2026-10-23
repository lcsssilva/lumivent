import 'package:lumivent/core/engine/engine_command.dart';
import 'package:lumivent/core/engine/engine_event.dart';
import 'package:lumivent/core/engine/engine_module.dart';

import 'ping.dart';
import 'pong.dart';
import 'started.dart';
import 'stopping.dart';

class EchoModule implements EngineModule {
  EchoModule(this.base);
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
