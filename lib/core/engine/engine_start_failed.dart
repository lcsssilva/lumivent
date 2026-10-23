part of 'isolate_engine.dart';

// Strings only: the original error may hold objects that cannot cross isolates.
class _EngineStartFailed extends EngineEvent {
  const _EngineStartFailed(this.error, this.stack);
  final String error;
  final String stack;
}
