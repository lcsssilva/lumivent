// Center column: 320×200 canvas with the effect preview behind and each
// canvas/fixed device drawn with its real LEDs. The GPU has no LEDs: its
// rectangle is drawn as the area whose average color it shows. Drag moves, the
// corner handle resizes.
//
// Devices in Hardware mode (or turned off) are not drawn: their LEDs are
// driven by the device itself, so there is nothing meaningful to preview.

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show Listenable, ValueListenable;
import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';

import '../../../core/ui/theme.dart';
import '../domain/led_layout.dart';
import '../domain/light_device.dart';
import '../domain/effect_runtime.dart';
import '../domain/lighting_config.dart';
import '../domain/native_effects.dart';
import '../domain/rgb.dart';

const _previewCols = 80;
const _previewRows = 50;
const _handlePx = 14.0;
const _minW = 10.0, _minH = 6.0;

/// New size after a resize drag. [room] is the space left to the canvas edge;
/// when it is below [min] the result is [room] (never throws).
double resizeExtent(double size, double delta, double min, double room) =>
    (size + delta).clamp(math.min(min, room), room).toDouble();

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

class LedCanvas extends StatefulWidget {
  const LedCanvas({
    super.key,
    required this.config,
    required this.time,
    required this.selected,
    required this.onSelect,
    required this.onPlace,
    this.frame,
  });
  final LightingConfig config;

  /// Effect clock in seconds, updated by the page ticker (~30 fps).
  final ValueListenable<double> time;
  final LightDeviceId? selected;
  final ValueChanged<LightDeviceId?> onSelect;
  final void Function(LightDeviceId id, CanvasRect rect) onPlace;

  /// Last frame of the installed HTML effect, when one is running.
  final ValueListenable<EffectFrame?>? frame;

  @override
  State<LedCanvas> createState() => _LedCanvasState();
}

class _LedCanvasState extends State<LedCanvas> {
  LightDeviceId? _drag;
  bool _resizing = false;
  Offset _start = Offset.zero;
  CanvasRect _startRect = const CanvasRect(0, 0, 1, 1);

  LightDeviceId? _hit(Offset p, double scale) {
    final cx = p.dx / scale, cy = p.dy / scale;
    for (final id in LightDeviceId.values.reversed) {
      if (!onCanvas(widget.config, id)) continue;
      final r = widget.config.device(id).placement;
      if (cx >= r.x && cx <= r.right && cy >= r.y && cy <= r.bottom) return id;
    }
    return null;
  }

  bool _onHandle(LightDeviceId id, Offset p, double scale) {
    final r = widget.config.device(id).placement;
    return (p.dx - r.right * scale).abs() <= _handlePx &&
        (p.dy - r.bottom * scale).abs() <= _handlePx;
  }

  void _panStart(Offset p, double scale) {
    final sel = widget.selected;
    LightDeviceId? id;
    var resizing = false;
    if (sel != null &&
        onCanvas(widget.config, sel) &&
        _onHandle(sel, p, scale)) {
      id = sel;
      resizing = true;
    } else {
      id = _hit(p, scale);
    }
    _drag = id;
    _resizing = resizing;
    _start = p;
    if (id != null) {
      _startRect = widget.config.device(id).placement;
      widget.onSelect(id);
    }
  }

  void _panUpdate(Offset p, double scale) {
    final id = _drag;
    if (id == null) return;
    final d = (p - _start) / scale;
    final r = _startRect;
    final next = _resizing
        ? CanvasRect(
            r.x,
            r.y,
            resizeExtent(r.w, d.dx, _minW, canvasWidth - r.x),
            resizeExtent(r.h, d.dy, _minH, canvasHeight - r.y),
          )
        : CanvasRect(
            (r.x + d.dx).clamp(0.0, canvasWidth - r.w),
            (r.y + d.dy).clamp(0.0, canvasHeight - r.h),
            r.w,
            r.h,
          );
    widget.onPlace(id, next);
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: canvasWidth / canvasHeight,
      child: LayoutBuilder(
        builder: (context, box) {
          final scale = box.maxWidth / canvasWidth;
          return GestureDetector(
            key: const ValueKey('led-canvas'),
            behavior: HitTestBehavior.opaque,
            // Report the pointer-down position so the corner resize handle is
            // tested where the user actually pressed, not after the pan slop.
            dragStartBehavior: DragStartBehavior.down,
            onTapDown: (d) => widget.onSelect(_hit(d.localPosition, scale)),
            onPanStart: (d) => _panStart(d.localPosition, scale),
            onPanUpdate: (d) => _panUpdate(d.localPosition, scale),
            onPanEnd: (_) => _drag = null,
            onPanCancel: () => _drag = null,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CustomPaint(
                painter: LedCanvasPainter(
                  config: widget.config,
                  selected: widget.selected,
                  time: widget.time,
                  frame: widget.frame,
                ),
                size: Size.infinite,
              ),
            ),
          );
        },
      ),
    );
  }
}

class LedCanvasPainter extends CustomPainter {
  LedCanvasPainter({
    required this.config,
    required this.selected,
    required this.time,
    this.frame,
  }) : super(repaint: Listenable.merge([time, ?frame]));

  final LightingConfig config;
  final LightDeviceId? selected;
  final ValueListenable<double> time;
  final ValueListenable<EffectFrame?>? frame;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / canvasWidth;
    final t = time.value;
    final bright = config.argbOff ? 0.0 : config.brightness;
    final effect = nativeEffectById(config.effectId);
    final values = config.effectValuesFor();

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF07080B),
    );

    Rgb sample(double x, double y) {
      final live = frame?.value;
      if (effect == null && live != null) {
        final ix = ((x / canvasWidth) * (live.width - 1)).round().clamp(
          0,
          live.width - 1,
        );
        final iy = ((y / canvasHeight) * (live.height - 1)).round().clamp(
          0,
          live.height - 1,
        );
        final (r, g, b) = live.pixelAt(ix, iy);
        return Rgb(r, g, b).scaled(bright);
      }
      return effect == null || values == null
          ? Rgb.black
          : effect.colorAt(x, y, t, values).scaled(bright);
    }

    // Preview behind: coarse grid, dimmed so the LEDs stand out.
    if ((effect != null && values != null) || frame?.value != null) {
      final cw = canvasWidth / _previewCols, ch = canvasHeight / _previewRows;
      final paint = Paint();
      for (var j = 0; j < _previewRows; j++) {
        for (var i = 0; i < _previewCols; i++) {
          final c = sample((i + .5) * cw, (j + .5) * ch);
          paint.color = Color.fromARGB(110, c.r, c.g, c.b);
          canvas.drawRect(
            Rect.fromLTWH(
              i * cw * scale,
              j * ch * scale,
              cw * scale + .5,
              ch * scale + .5,
            ),
            paint,
          );
        }
      }
    }

    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final led = Paint();
    for (final id in LightDeviceId.values) {
      if (!onCanvas(config, id)) continue;
      final dev = config.device(id);
      final r = dev.placement;
      final layout = ledLayoutFor(id, fanQuantity: config.fansOf(id));
      final rect = Rect.fromLTWH(
        r.x * scale,
        r.y * scale,
        r.w * scale,
        r.h * scale,
      );
      final isSel = id == selected;
      outline.color = isSel ? WeColors.accentHover : const Color(0x55FFFFFF);
      outline.strokeWidth = isSel ? 1.5 : 1;
      // The GPU rectangle is a sampling window, not a dark device body: let
      // the effect preview show through so the user sees the averaged area.
      if (id != LightDeviceId.gpu) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          Paint()..color = const Color(0x99000000),
        );
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        outline,
      );
      final radius = (rect.shortestSide * .06).clamp(1.5, 5.0);
      for (final p in layout.leds) {
        final (x, y) = r.map(p);
        final c = dev.mode == LightMode.fixed
            ? dev.fixedColor.scaled(bright)
            : sample(x, y);
        led.color = Color.fromARGB(255, c.r, c.g, c.b);
        canvas.drawCircle(Offset(x * scale, y * scale), radius, led);
      }
      if (isSel) {
        canvas.drawRect(
          Rect.fromCenter(center: rect.bottomRight, width: 10, height: 10),
          Paint()..color = WeColors.accentHover,
        );
      }
    }
  }

  @override
  bool shouldRepaint(LedCanvasPainter old) =>
      old.config != config ||
      old.selected != selected ||
      old.time != time ||
      old.frame != frame;
}
