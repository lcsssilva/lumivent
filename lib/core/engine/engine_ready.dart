part of 'isolate_engine.dart';

class _EngineReady extends EngineEvent {
  const _EngineReady(this.commands);
  final SendPort commands;
}
