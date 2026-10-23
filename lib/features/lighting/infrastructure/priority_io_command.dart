part of 'light_io_command.dart';

/// A priority command discards the droppable ones still waiting.
sealed class PriorityIoCommand extends LightIoCommand {
  const PriorityIoCommand();
}
