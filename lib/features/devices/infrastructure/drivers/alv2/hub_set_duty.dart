part of 'alv2_hub_command.dart';

class HubSetDuty extends Alv2HubCommand {
  const HubSetDuty(this.group, this.duty);
  final int group, duty;
}
