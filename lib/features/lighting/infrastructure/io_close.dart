part of 'light_io_command.dart';

/// Closes the drivers this worker owns; nothing runs after it.
class IoClose extends PriorityIoCommand {
  const IoClose();
}
