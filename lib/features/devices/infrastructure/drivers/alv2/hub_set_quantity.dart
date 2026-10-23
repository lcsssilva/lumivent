part of 'alv2_hub_command.dart';

class HubSetQuantity extends Alv2HubCommand {
  const HubSetQuantity(this.group, this.quantity);
  final int group, quantity;
}
