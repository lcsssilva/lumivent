import 'engine_event.dart';

// Strings only: the original error may hold objects that cannot cross isolates.
class EngineStartFailed extends EngineEvent {
  const EngineStartFailed(this.error, this.stack);
  final String error;
  final String stack;
}
