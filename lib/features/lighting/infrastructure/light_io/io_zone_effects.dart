part of 'light_io_command.dart';

/// Hardware effects of several zones (keys `0x20`/`0x22`/`0x23`) in one batch.
class IoZoneEffects extends LightIoCommand {
  const IoZoneEffects(this.zones);
  final Map<int, BoardZoneConfig> zones;
}
