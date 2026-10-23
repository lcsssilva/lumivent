part of 'alv2_hub_command.dart';

class HubSendLighting extends Alv2HubCommand {
  const HubSendLighting(
    this.writes, {
    this.frame = true,
    this.priority = false,
  });
  final List<Alv2PortWrite> writes;
  final bool frame, priority;
}
