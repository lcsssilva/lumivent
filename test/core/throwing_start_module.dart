import 'package:lumivent/core/engine/engine_command.dart';
import 'package:lumivent/core/engine/engine_event.dart';
import 'package:lumivent/core/engine/engine_module.dart';

class ThrowingStartModule implements EngineModule {
  @override
  void start(void Function(EngineEvent) emit) => throw StateError('start boom');

  @override
  bool handle(EngineCommand command) => false;

  @override
  void stop() {}
}
