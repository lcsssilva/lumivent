import '../../../../core/engine/engine_command.dart';
import 'set_lighting_config.dart';

/// Turns all ARGB off/on (top bar, tray). The engine also receives the full
/// config through [SetLightingConfig]; this one stays for the shortcut paths.
class SetArgbOff extends EngineCommand {
  const SetArgbOff(this.off);
  final bool off;
}
