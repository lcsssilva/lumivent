import '../../../core/engine/engine_host.dart';

/// Frame rate of the LED loop (preferences: 15/30/60). The engine clamps the
/// value to a sane range.
class SetLightingFps extends EngineCommand {
  const SetLightingFps(this.fps);
  final int fps;
}
