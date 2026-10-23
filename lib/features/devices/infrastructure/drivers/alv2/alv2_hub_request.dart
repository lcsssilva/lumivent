import 'alv2_hub_command.dart';

class Alv2HubRequest {
  const Alv2HubRequest(this.id, this.command);
  final int id;
  final Alv2HubCommand command;
}
