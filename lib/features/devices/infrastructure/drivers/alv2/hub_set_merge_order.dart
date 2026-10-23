part of 'alv2_hub_command.dart';

class HubSetMergeOrder extends Alv2HubCommand {
  const HubSetMergeOrder(this.order);
  final List<int> order;
}
