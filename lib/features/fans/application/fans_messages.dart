import '../../../core/engine/engine_host.dart';
import '../domain/fan_group.dart';

/// New fan configuration (the engine uses it on the next cycle).
class SetFansConfig extends EngineCommand {
  const SetFansConfig(this.config);
  final FansConfig config;
}

/// Group state from the last loop cycle.
class FanGroupStatus {
  const FanGroupStatus({
    required this.group,
    this.temp,
    this.rawTemp,
    this.targetRpm,
    this.duty,
  });
  final int group;

  /// Average temperature (used by the curve); `null` = no reading (group is not
  /// updated).
  final double? temp;

  /// Raw source reading in this cycle.
  final double? rawTemp;

  /// RPM the curve requests now.
  final int? targetRpm;

  /// Duty sent (after ramping); `null` if nothing was sent (no
  /// temperature or hub missing).
  final int? duty;
}

/// Result of each fan loop cycle (every 1 second).
class FansStatus extends EngineEvent {
  const FansStatus(this.groups, {required this.hubOk, this.syncOff = false});
  final List<FanGroupStatus> groups;

  /// The hub accepted this cycle's packets.
  final bool hubOk;

  /// The motherboard RPM sync was turned off this session (the vendor software may have
  /// left it on in Windows; the hub cannot report it, so this is what the app
  /// did, not what it read).
  final bool syncOff;
}
