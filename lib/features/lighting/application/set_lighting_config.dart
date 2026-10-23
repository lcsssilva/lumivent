import '../../../core/engine/engine_command.dart';
import '../domain/lighting_config.dart';

/// New lighting configuration. The engine applies only what changed:
/// hardware modes are resent when their settings change, canvas/fixed devices
/// follow on the next frame.
class SetLightingConfig extends EngineCommand {
  const SetLightingConfig(this.config);
  final LightingConfig config;
}
