import '../../../core/engine/engine_command.dart';

/// "Identify" button of a fan group (AL V2 ping, AL-V2 §4). [group] is the
/// hub group (1–3).
class IdentifyFanGroup extends EngineCommand {
  const IdentifyFanGroup(this.group);
  final int group;
}
