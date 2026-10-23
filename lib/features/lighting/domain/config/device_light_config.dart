import 'package:freezed_annotation/freezed_annotation.dart';

import '../canvas/canvas_rect.dart';
import '../light_device.dart';
import '../rgb.dart';

part 'device_light_config.freezed.dart';

@freezed
abstract class DeviceLightConfig with _$DeviceLightConfig {
  const factory DeviceLightConfig({
    @Default(true) bool enabled,
    @Default(LightMode.canvas) LightMode mode,
    @Default(Rgb.white) Rgb fixedColor,
    required CanvasRect placement,
  }) = _DeviceLightConfig;

  /// Default for [id]: enabled in Canvas at the default position.
  factory DeviceLightConfig.defaults(LightDeviceId id) => DeviceLightConfig(
    enabled: id.isSupported,
    placement: CanvasRect.defaultFor(id),
  );
}
