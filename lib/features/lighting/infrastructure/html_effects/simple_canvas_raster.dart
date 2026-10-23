// Fast path for effects that only fill solid rectangles (Rainbow, Gradient
// Mesh, Audio Bars...). It writes an RGBA framebuffer directly instead of
// recording a dart:ui picture and reading it back, which is the most expensive
// part of the 30 fps loop on Linux.
//
// The subset is intentionally conservative: any transform, path, gradient,
// alpha or non-srcOver blending falls back to `CanvasReplayer`.

import 'dart:typed_data';

import 'canvas_op.dart';
import 'canvas_command_buffer.dart';
import 'css_color.dart';
import 'hsl_color.dart';
import 'simple_raster_state.dart';
import 'simple_raster.dart';

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
    bool mustCover = false,
  }) {
    final pixels = Uint32List(width * height);
    if (previous != null) {
      pixels.setAll(0, previous);
    }
    return rasterInto(
      pixels,
      encoded,
      firstFrame: previous == null && !mustCover,
      mustCover: mustCover,
      state: state,
    );
  }

  /// Per-render-isolate fast path: rasterizes [encoded] into [pixels],
  /// mutating it instead of allocating and copying a fresh buffer every
  /// frame. [pixels] must hold the previous fast frame; a first frame starts
  /// from opaque black ([firstFrame]). Returns null when the frame needs the
  /// general dart:ui replay — in that case [pixels] must be discarded: the
  /// shim's incremental state no longer matches the buffer.
  ///
  /// [mustCover] is for a frame that follows a general-replay frame: the
  /// contents of [pixels] are unknown, so the frame is only accepted when its
  /// first pixel-writing command covers the whole canvas with a known value.
  static SimpleRaster? rasterInto(
    Uint32List pixels,
    Uint8List encoded, {
    required bool firstFrame,
    bool mustCover = false,
    SimpleRasterState state = const SimpleRasterState(),
  }) {
    if (firstFrame) {
      pixels.fillRange(0, pixels.length, 0xff000000);
    }
    var covered = !mustCover;
    final ops = CanvasCommandBuffer(encoded);
    // The first pixel-writing rectangle of a [mustCover] frame must cover the
    // canvas; returns false when it does not, which rejects the frame.
    bool coverRect() {
      if (covered) return true;
      if (!_covers(
        ops.number(0),
        ops.number(1),
        ops.number(2),
        ops.number(3),
      )) {
        return false;
      }
      covered = true;
      return true;
    }

    int? color = state.fill;
    double? alpha = state.alpha;
    bool? srcOver = state.srcOver;
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
          if (alpha != 1 || srcOver != true || color == null) return null;
          if (!coverRect()) return null;
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
          if (alpha != 1 || srcOver != true) return null;
          final packed = ops.color(4);
          if ((packed >>> 24) != 255) return null;
          if (!coverRect()) return null;
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
          if (alpha != 1 || srcOver != true) return null;
          if (!coverRect()) return null;
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
          // clearRect ignores alpha and composite (canvas spec).
          if (!coverRect()) return null;
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

  /// The context state after the general replay drew [encoded] on top of
  /// [state]: tracks the styles the fast path understands so an effect that
  /// sets its style once can resume the fast path after an occasional
  /// fallback. Anything it cannot mirror becomes unknown.
  static SimpleRasterState stateAfterReplay(
    Uint8List encoded,
    SimpleRasterState state,
  ) {
    int? fill = state.fill;
    double? alpha = state.alpha;
    bool? srcOver = state.srcOver;
    final ops = CanvasCommandBuffer(encoded);
    try {
      while (ops.next()) {
        switch (ops.opcode) {
          case CanvasOp.fillStyle:
            if (ops.isGradient(0)) {
              fill = null;
            } else {
              final argb = ops.isColor(0)
                  ? ops.color(0)
                  : parseCssColor(ops.text(0))?.toARGB32();
              fill = argb != null && (argb >>> 24) == 255 ? argb : null;
            }
          case CanvasOp.hslStyle:
            fill = hslArgb(ops.number(0), ops.number(1), ops.number(2));
          case CanvasOp.alpha:
            final value = ops.number(0);
            if (value >= 0 && value <= 1) alpha = value;
          case CanvasOp.composite:
            srcOver = ops.text(0) == 'source-over';
          case CanvasOp.restore:
            fill = null;
            alpha = null;
            srcOver = null;
        }
      }
    } on FormatException {
      return SimpleRasterState.unknown;
    }
    return SimpleRasterState(fill: fill, alpha: alpha, srcOver: srcOver);
  }

  /// Whether the rectangle covers the whole canvas after rounding and clamping
  /// (the same geometry as [_fill]).
  static bool _covers(double x, double y, double w, double h) {
    if (!x.isFinite || !y.isFinite || !w.isFinite || !h.isFinite) return false;
    final x0 = x.round(), x1 = (x + w).round();
    final y0 = y.round(), y1 = (y + h).round();
    return (x0 < x1 ? x0 : x1) <= 0 &&
        (x0 < x1 ? x1 : x0) >= width &&
        (y0 < y1 ? y0 : y1) <= 0 &&
        (y0 < y1 ? y1 : y0) >= height;
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
    // Canvas spec: a rect with a non-finite argument draws nothing.
    if (!x.isFinite || !y.isFinite || !w.isFinite || !h.isFinite) return true;
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
