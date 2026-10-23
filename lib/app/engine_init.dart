import '../features/fans/fans.dart';
import '../features/lighting/lighting.dart';

/// Initial state the engine needs from the UI.
class EngineInit {
  const EngineInit({
    required this.lighting,
    required this.lightingFps,
    required this.fans,
  });
  final LightingConfig lighting;

  /// Frame rate of the LED loop (preferences); changes later arrive as a
  /// `SetLightingFps` command.
  final int lightingFps;
  final FansConfig fans;
}
