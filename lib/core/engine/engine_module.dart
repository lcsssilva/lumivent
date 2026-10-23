import 'dart:async';

import 'isolate_engine.dart';
import 'engine_command.dart';
import 'engine_event.dart';

/// Part of a module that runs inside the engine.
abstract interface class EngineModule {
  void start(void Function(EngineEvent) emit);

  /// Handles [command] if it belongs to this module; returns `false` otherwise.
  bool handle(EngineCommand command);

  /// Stops the module. May be asynchronous (flushing a worker isolate): the
  /// engine waits for each module, in reverse order, up to [moduleStopTimeout].
  FutureOr<void> stop();
}
