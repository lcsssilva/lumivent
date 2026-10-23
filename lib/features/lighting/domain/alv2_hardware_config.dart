part of 'lighting_config.dart';

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
