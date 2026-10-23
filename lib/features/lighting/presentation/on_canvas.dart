import '../domain/led_layout.dart';
import '../domain/light_device.dart';
import '../domain/lighting_config.dart';

/// Devices that appear on the canvas.
///
/// The GPU has no addressable LEDs but still has an area: its whole rectangle
/// is sampled for the average color, so the rectangle must stay visible and
/// draggable.
bool onCanvas(LightingConfig cfg, LightDeviceId id) {
  final d = cfg.device(id);
  final hasArea =
      id == LightDeviceId.gpu ||
      ledLayoutFor(id, fanQuantity: cfg.fansOf(id)).length > 0;
  return id.isSupported && d.enabled && d.mode != LightMode.hardware && hasArea;
}
