import 'dart:isolate';

import 'engine_event.dart';

class EngineReady extends EngineEvent {
  const EngineReady(this.commands);
  final SendPort commands;
}
