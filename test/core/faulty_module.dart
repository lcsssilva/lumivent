import 'package:lumivent/core/engine/engine_command.dart';
import 'package:lumivent/core/engine/engine_event.dart';
import 'package:lumivent/core/engine/engine_module.dart';

import 'boom.dart';

/// Throws on [Boom] in handle, and/or in stop when [throwOnStop] is set.
class FaultyModule implements EngineModule {
  FaultyModule({this.throwOnStop = false});
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
