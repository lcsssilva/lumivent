part of 'alv2_hub_command.dart';

class HubStreamCanvas extends Alv2HubCommand {
  const HubStreamCanvas(this.writes);
  final List<Alv2PortWrite> writes;
}
