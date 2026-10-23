import '../../../core/engine/engine_command.dart';
import '../domain/light_device.dart';
import '../domain/rgb.dart';

/// LEDs sampled from an HTML effect frame (plan §5.5). Sent by the UI
/// isolate at the effects FPS; [effectId] must be the current global effect,
/// otherwise the frame is stale and ignored by the engine.
class SetHtmlEffectFrame extends EngineCommand {
  const SetHtmlEffectFrame(this.effectId, this.pixels);
  final String effectId;
  final Map<LightDeviceId, List<Rgb>> pixels;
}
