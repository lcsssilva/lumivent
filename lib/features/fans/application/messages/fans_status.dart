import '../../../../core/engine/engine_event.dart';
import '../fan_group_status.dart';

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
