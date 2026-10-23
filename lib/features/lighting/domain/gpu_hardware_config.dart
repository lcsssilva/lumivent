part of 'lighting_config.dart';

/// Hardware mode of the GPU: effect, speed/brightness (0–10) and colors.
@freezed
abstract class GpuHardwareConfig with _$GpuHardwareConfig {
  const factory GpuHardwareConfig({
    @Default(GpuEffect.pulse) GpuEffect effect,

    /// 0–10.
    @Default(5) int speed,

    /// 0–10.
    @Default(10) int brightness,

    /// Single color of effects without a palette.
    @Default(Rgb.white) Rgb color,
    @Default(_gpuDefaultColors) List<Rgb> colors,
  }) = _GpuHardwareConfig;

  /// Default palette for `ColorShift`; also the fallback for missing entries.
  static const defaultColors = _gpuDefaultColors;
}
