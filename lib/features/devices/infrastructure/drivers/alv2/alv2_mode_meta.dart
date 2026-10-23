import 'lighting.dart';

/// UI metadata for a mode (AL-V2 §6).
///
/// §6 only describes "whole fan" modes. Interpretation: every mode has speed
/// except StaticColor ("no speed"); only modes with `dir` have direction.
/// Inner/outer modes and merge **inherit** the metadata of the whole-fan mode of
/// the same base name (inferred); Lottery, PacMan, and outer-ring
/// Colorful/Rainbow variants have no pair and use assumed values.
class Alv2ModeMeta {
  const Alv2ModeMeta({
    this.speed = true,
    this.direction = false,
    this.colors = 0,
    this.defaultSpeedLevel = 3,
    this.defaultDirection = 0,
    this.whiteDefault = false,
  });

  /// Has speed control.
  final bool speed;

  /// Has direction control.
  final bool direction;

  /// How many colors the UI lets the user pick.
  final int colors;

  /// Level 0–4 (default 75% = 3).
  final int defaultSpeedLevel;

  /// 0 = right, 1 = left.
  final int defaultDirection;

  /// ElectricCurrent: default white colors.
  final bool whiteDefault;

  /// Default colors (flat R,G,B): §4 factory palette (red, blue, green, yellow,
  /// orange, cyan), truncated to [colors]. For non-static modes this is inferred
  /// (`ALV2FanProfile..cctor` is not in the documents).
  List<int> get defaultColors => [
    for (var i = 0; i < colors; i++)
      ...(whiteDefault ? const [255, 255, 255] : alv2FactoryPalette[i % 6]),
  ];
}
