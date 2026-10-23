import 'lighting.dart';

/// Effect for a mode with its UI settings (levels 0–4, direction 0/1).
class Alv2Effect {
  const Alv2Effect(
    this.mode, {
    this.colors = const [],
    this.speedLevel = 3,
    this.direction = 0,
    this.brightnessLevel = 4,
  });

  final Alv2LightMode mode;

  /// UI colors, flat R,G,B.
  final List<int> colors;
  final int speedLevel, direction, brightnessLevel;
}
