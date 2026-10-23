import 'dart:async';

import 'engine_command.dart';
import 'engine_event.dart';

/// What the UI uses from the engine. Implemented by the real isolate and by fakes.
abstract interface class EngineApi {
  Stream<EngineEvent> get events;

  /// Last event received of type [T] (the UI can subscribe after receiving it).
  T? lastEvent<T extends EngineEvent>();
  void send(EngineCommand command);
  Future<void> shutdown();
}
