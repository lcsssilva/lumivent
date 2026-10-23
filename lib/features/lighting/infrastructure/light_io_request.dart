import 'light_io_command.dart';

class LightIoRequest {
  const LightIoRequest(this.id, this.command);
  final int id;
  final LightIoCommand command;
}
