// Lighting module domain (pure Dart): samples an effect frame at each LED
// position (plan §5.5). Fans, case, board and memory all read the same canvas.

import 'effect_runtime.dart';
import 'led_layout.dart';
import 'light_device.dart';
import 'lighting_config.dart';
import 'rgb.dart';

/// Colors of the canvas devices for [frame], in the order each driver expects.
///
/// Disabled devices, Fixed and Hardware modes, and `argbOff` are left out: the
/// engine already uses the fixed color, turns them off, or hands them to the
/// firmware. Brightness is applied by the engine, so the frame keeps the
/// effect's own colors.
Map<LightDeviceId, List<Rgb>> sampleEffectFrame(
  LightingConfig config,
  EffectFrame frame,
) {
  final out = <LightDeviceId, List<Rgb>>{};
  if (config.argbOff) return out;
  for (final id in LightDeviceId.values) {
    if (!id.isSupported) continue;
    final d = config.device(id);
    if (!d.enabled || d.mode != LightMode.canvas) continue;
    if (id == LightDeviceId.gpu) {
      // The GPU has one color: the average of its rectangle.
      const cols = 12, rows = 8;
      final rect = d.placement;
      var r = 0, g = 0, b = 0;
      for (var iy = 0; iy < rows; iy++) {
        final y = rect.y + (iy + 0.5) * rect.h / rows;
        for (var ix = 0; ix < cols; ix++) {
          final x = rect.x + (ix + 0.5) * rect.w / cols;
          final (pr, pg, pb) = frame.pixelAt(x.floor(), y.floor());
          r += pr;
          g += pg;
          b += pb;
        }
      }
      final n = cols * rows;
      out[id] = [Rgb((r / n).round(), (g / n).round(), (b / n).round())];
      continue;
    }
    final layout = ledLayoutFor(id, fanQuantity: config.fansOf(id));
    if (layout.length == 0) continue;
    final colors = List<Rgb>.generate(layout.length, (i) {
      final (x, y) = d.placement.map(layout.leds[i]);
      final (r, g, b) = frame.pixelAt(x.floor(), y.floor());
      return Rgb(r, g, b);
    }, growable: false);
    out[id] = colors;
  }
  return out;
}
