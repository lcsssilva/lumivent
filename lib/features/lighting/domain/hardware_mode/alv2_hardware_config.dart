import 'package:freezed_annotation/freezed_annotation.dart';

import '../config/lighting_config.dart';
import '../rgb.dart';

part 'alv2_hardware_config.freezed.dart';

// Top-level constants are usable from the generated part; static members are
// not inherited by the generated implementation class.
const _alv2DefaultColors = [
  Rgb(255, 0, 0),
  Rgb(0, 0, 255),
  Rgb(0, 255, 0),
  Rgb(255, 255, 0),
  Rgb(255, 128, 0),
  Rgb(0, 255, 255),
];

/// Hardware mode for a hub group. The domain stores only the mode name
/// (`Rainbow`, `StaticColor_Inner`…); the byte table belongs to devices.
@freezed
abstract class Alv2HardwareConfig with _$Alv2HardwareConfig {
  const factory Alv2HardwareConfig({
    @Default(Alv2Scope.whole) Alv2Scope scope,
    @Default('StaticColor') String mode,

    /// Speed level, 0–4 (2 = normal).
    @Default(2) int speed,

    /// Brightness level, 0–4 (4 = 100%).
    @Default(4) int brightness,
    @Default(false) bool directionLeft,
    @Default(_alv2DefaultColors) List<Rgb> colors,
  }) = _Alv2HardwareConfig;

  /// Factory default (AL-V2 §4).
  static const defaultColors = _alv2DefaultColors;
}
