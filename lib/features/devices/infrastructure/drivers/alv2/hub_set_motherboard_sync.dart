part of 'alv2_hub_command.dart';

class HubSetMotherboardSync extends Alv2HubCommand {
  const HubSetMotherboardSync(this.sync);
  final List<bool> sync;
}
