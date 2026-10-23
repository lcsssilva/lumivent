part of 'alv2_hub_command.dart';

class HubIdentify extends Alv2HubCommand {
  const HubIdentify(this.group, {this.merge = false});
  final int group;
  final bool merge;
}
