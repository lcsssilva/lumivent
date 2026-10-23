import 'engine_command.dart';
import 'engine_stopped.dart';

/// Closes all modules; the engine responds with [EngineStopped] and exits.
class ShutdownEngine extends EngineCommand {
  const ShutdownEngine();
}
