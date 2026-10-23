import 'package:freezed_annotation/freezed_annotation.dart';

import 'lighting_config.dart';
import 'rgb.dart';

part 'gpu_hardware_config.freezed.dart';

// Top-level constants are usable from the generated part; static members are
// not inherited by the generated implementation class.
const _gpuDefaultColors = [
  Rgb(255, 0, 0),
  Rgb(255, 128, 0),
  Rgb(255, 255, 0),
  Rgb(0, 255, 0),
  Rgb(0, 255, 255),
  Rgb(0, 0, 255),
  Rgb(160, 0, 255),
  Rgb(255, 255, 255),
];

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
