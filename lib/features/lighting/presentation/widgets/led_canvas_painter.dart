import 'package:flutter/foundation.dart' show Listenable, ValueListenable;
import 'package:flutter/material.dart';

import '../../../../core/ui/we_colors.dart';
import '../../domain/led_layout.dart';
import '../../domain/light_device.dart';
import '../../domain/effect_frame.dart';
import '../../domain/lighting_config.dart';
import '../../domain/native_effects.dart';
import '../../domain/rgb.dart';
import '../on_canvas.dart';

const _previewCols = 80;
const _previewRows = 50;

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
