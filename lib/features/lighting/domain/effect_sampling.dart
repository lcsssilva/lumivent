// Lighting module domain (pure Dart): samples an effect frame at each LED
// position (plan §5.5). Fans, case, board and memory all read the same canvas.

import 'dart:typed_data';

import 'effect_frame.dart';
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
) => _colorsByPoint(canvasSamplePoints(config), frame.pixelAt);

/// Where the frame is sampled for [config]: one `(device, x, y)` entry per LED
/// of every enabled canvas device, in driver order, with the pixels given in
/// driver order too. The GPU is the average of its rectangle; the colors are
/// assembled by [sampleEffectFrame] (byte frame) and [sampleCanvasPixels]
/// (`Uint32List` canvas, on the render isolate).
List<(LightDeviceId, int, int)> canvasSamplePoints(LightingConfig config) {
  final out = <(LightDeviceId, int, int)>[];
  if (config.argbOff) return out;
  for (final id in LightDeviceId.values) {
    if (!id.isSupported) continue;
    final d = config.device(id);
    if (!d.enabled || d.mode != LightMode.canvas) continue;
    if (id == LightDeviceId.gpu) {
      // The GPU has one color: the average of its rectangle.
      const cols = 12, rows = 8;
      final rect = d.placement;
      for (var iy = 0; iy < rows; iy++) {
        final y = rect.y + (iy + 0.5) * rect.h / rows;
        for (var ix = 0; ix < cols; ix++) {
          final x = rect.x + (ix + 0.5) * rect.w / cols;
          out.add((id, x.floor(), y.floor()));
        }
      }
      continue;
    }
    final layout = ledLayoutFor(id, fanQuantity: config.fansOf(id));
    if (layout.length == 0) continue;
    for (var i = 0; i < layout.length; i++) {
      final (x, y) = d.placement.map(layout.leds[i]);
      out.add((id, x.floor(), y.floor()));
    }
  }
  return out;
}

/// Colors per device from [points] over a `width × height` canvas (one
/// `0xAABBGGRR` pixel per word, little endian — the layout of
/// `SimpleCanvasRaster`, kept as its own copy per frame on the UI isolate).
Map<LightDeviceId, List<Rgb>> sampleCanvasPixels(
  List<(LightDeviceId, int, int)> points,
  Uint32List pixels, {
  int width = canvasWidth,
  int height = canvasHeight,
}) => _colorsByPoint(points, (x, y) {
  final v = pixels[(y.clamp(0, height - 1) * width) + x.clamp(0, width - 1)];
  return ((v & 0xFF), (v >> 8) & 0xFF, (v >> 16) & 0xFF);
});

/// Groups [pixel] readings by device and turns the GPU sample grid into its
/// single average color, like the direct frame sampler did.
Map<LightDeviceId, List<Rgb>> _colorsByPoint(
  List<(LightDeviceId, int, int)> points,
  (int, int, int) Function(int x, int y) pixel,
) {
  final out = <LightDeviceId, List<Rgb>>{};
  for (final (id, x, y) in points) {
    final (r, g, b) = pixel(x, y);
    (out[id] ??= []).add(Rgb(r, g, b));
  }
  final gpu = out.remove(LightDeviceId.gpu);
  if (gpu != null && gpu.isNotEmpty) {
    var r = 0, g = 0, b = 0;
    for (final c in gpu) {
      r += c.r;
      g += c.g;
      b += c.b;
    }
    final n = gpu.length;
    out[LightDeviceId.gpu] = [
      Rgb((r / n).round(), (g / n).round(), (b / n).round()),
    ];
  }
  return out;
}
