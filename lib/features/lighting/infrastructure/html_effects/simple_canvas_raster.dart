// Fast path for effects that only fill solid rectangles (Rainbow, Gradient
// Mesh, Audio Bars...). It writes an RGBA framebuffer directly instead of
// recording a dart:ui picture and reading it back, which is the most expensive
// part of the 30 fps loop on Linux.
//
// The subset is intentionally conservative: any transform, path, gradient,
// alpha or non-srcOver blending falls back to `CanvasReplayer`.

import 'dart:typed_data';

import 'canvas_buffer.dart';
import 'css_color.dart';
import 'hsl_color.dart';

/// Context state that survives between fast frames (the shim only sends
/// changes, just like a real canvas).
class SimpleRasterState {
  const SimpleRasterState({
    this.fill = 0xff000000,
    this.alpha = 1,
    this.srcOver = true,
  });

  final int fill;
  final double alpha;
  final bool srcOver;

  @override
  bool operator ==(Object other) =>
      other is SimpleRasterState &&
      other.fill == fill &&
      other.alpha == alpha &&
      other.srcOver == srcOver;

  @override
  int get hashCode => Object.hash(fill, alpha, srcOver);
}

/// Result of [SimpleCanvasRaster.tryRaster] / [SimpleCanvasRaster.rasterInto].
class SimpleRaster {
  const SimpleRaster(this.pixels, this.opCount, this.state);

  /// RGBA8888, little endian (`0xAABBGGRR` per pixel).
  final Uint32List pixels;
  final int opCount;
  final SimpleRasterState state;

  Uint8List get rgba =>
      Uint8List.view(pixels.buffer, pixels.offsetInBytes, pixels.lengthInBytes);
}

abstract final class SimpleCanvasRaster {
  static const width = 320, height = 200;

  /// Returns null when the frame needs the general dart:ui replay.
  ///
  /// [previous] is the previous fast frame (the browser canvas preserves its
  /// contents between frames).
  static SimpleRaster? tryRaster(
    Uint8List encoded, {
    Uint32List? previous,
    SimpleRasterState state = const SimpleRasterState(),
  }) {
    final pixels = Uint32List(width * height);
    if (previous != null) {
      pixels.setAll(0, previous);
    }
    return rasterInto(
      pixels,
      encoded,
      firstFrame: previous == null,
      state: state,
    );
  }

  /// Per-render-isolate fast path: rasterizes [encoded] into [pixels],
  /// mutating it instead of allocating and copying a fresh buffer every
  /// frame. [pixels] must hold the previous fast frame; a first frame starts
  /// from opaque black ([firstFrame]). Returns null when the frame needs the
  /// general dart:ui replay — in that case [pixels] must be discarded: the
  /// shim's incremental state no longer matches the buffer.
  static SimpleRaster? rasterInto(
    Uint32List pixels,
    Uint8List encoded, {
    required bool firstFrame,
    SimpleRasterState state = const SimpleRasterState(),
  }) {
    if (firstFrame) {
      pixels.fillRange(0, pixels.length, 0xff000000);
    }
    final ops = CanvasCommandBuffer(encoded);
    var color = state.fill;
    var alpha = state.alpha;
    var srcOver = state.srcOver;
    while (ops.next()) {
      switch (ops.opcode) {
        case CanvasOp.fillStyle:
          if (ops.isColor(0)) {
            color = ops.color(0);
          } else {
            final parsed = parseCssColor(ops.text(0));
            if (parsed == null) return null;
            color = parsed.toARGB32();
          }
          if ((color >>> 24) != 255) return null;
        case CanvasOp.hslStyle:
          color = hslArgb(ops.number(0), ops.number(1), ops.number(2));
        case CanvasOp.alpha:
          alpha = ops.number(0);
        case CanvasOp.composite:
          srcOver = ops.text(0) == 'source-over';
        case CanvasOp.fillRect:
          if (alpha != 1 || !srcOver) return null;
          if (!_fill(
            pixels,
            ops.number(0),
            ops.number(1),
            ops.number(2),
            ops.number(3),
            color,
          )) {
            return null;
          }
        case CanvasOp.fillRect16:
          if (alpha != 1 || !srcOver) return null;
          final packed = ops.color(4);
          if ((packed >>> 24) != 255) return null;
          if (!_fill(
            pixels,
            ops.number(0),
            ops.number(1),
            ops.number(2),
            ops.number(3),
            packed,
          )) {
            return null;
          }
        case CanvasOp.fillRect16Hsl:
          if (alpha != 1 || !srcOver) return null;
          if (!_fill(
            pixels,
            ops.number(0),
            ops.number(1),
            ops.number(2),
            ops.number(3),
            hslArgb(ops.number(4), ops.number(5), ops.number(6)),
          )) {
            return null;
          }
        case CanvasOp.clearRect:
          _fill(
            pixels,
            ops.number(0),
            ops.number(1),
            ops.number(2),
            ops.number(3),
            0,
          );
        case CanvasOp.strokeStyle:
        case CanvasOp.lineWidth:
        case CanvasOp.lineCap:
        case CanvasOp.lineJoin:
          // No effect on fills.
          break;
        default:
          return null;
      }
    }
    return SimpleRaster(
      pixels,
      ops.count,
      SimpleRasterState(fill: color, alpha: alpha, srcOver: srcOver),
    );
  }

  /// Fills [rect] with a packed ARGB color; 0 means transparent.
  static bool _fill(
    Uint32List pixels,
    double x,
    double y,
    double w,
    double h,
    int argb,
  ) {
    var x0 = x.round();
    var y0 = y.round();
    var x1 = (x + w).round();
    var y1 = (y + h).round();
    if (x1 < x0) {
      final t = x0;
      x0 = x1;
      x1 = t;
    }
    if (y1 < y0) {
      final t = y0;
      y0 = y1;
      y1 = t;
    }
    if (x0 < 0) x0 = 0;
    if (y0 < 0) y0 = 0;
    if (x1 > width) x1 = width;
    if (y1 > height) y1 = height;
    if (x0 >= x1 || y0 >= y1) return true;
    final value = argb == 0
        ? 0
        : 0xff000000 |
              ((argb & 0xff) << 16) |
              (((argb >> 8) & 0xff) << 8) |
              ((argb >> 16) & 0xff);
    for (var yy = y0; yy < y1; yy++) {
      final row = yy * width;
      pixels.fillRange(row + x0, row + x1, value);
    }
    return true;
  }
}
