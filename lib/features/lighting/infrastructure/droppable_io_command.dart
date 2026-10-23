part of 'light_io_command.dart';

/// Skipped (`ok == false`, `dropped`) if a priority command arrived after it
/// and before it started.
sealed class DroppableIoCommand extends LightIoCommand {
  const DroppableIoCommand();
}
