part of 'fan_curve_editor.dart';

class _FanCurvePainter extends CustomPainter {
  _FanCurvePainter(
    this.group,
    this.live,
    this.plot,
    this.dragging,
    this.strings,
  );

  final FanGroupConfig group;
  final FanCurveLive live;
  final _FanCurvePlot plot;
  final int? dragging;
  final AppStrings strings;

  double _pct(num rpm) =>
      (rpm / group.size.maxRpm * 100).clamp(0, 100).toDouble();

  void _text(
    Canvas canvas,
    String s,
    Offset at, {
    Color color = WeColors.muted,
    TextAlign align = TextAlign.left,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(fontFamily: 'Inter', color: color, fontSize: 11),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = switch (align) {
      TextAlign.right => -tp.width,
      TextAlign.center => -tp.width / 2,
      _ => 0.0,
    };
    tp.paint(canvas, at + Offset(dx, -tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final r = plot.rect;
    final grid = Paint()
      ..color = WeColors.border
      ..strokeWidth = 1;

    // Grid and axes.
    for (var t = 0; t <= 100; t += 10) {
      canvas.drawLine(
        Offset(plot.x(t.toDouble()), r.top),
        Offset(plot.x(t.toDouble()), r.bottom),
        grid,
      );
      _text(
        canvas,
        '$t',
        Offset(plot.x(t.toDouble()), r.bottom + 12),
        align: TextAlign.center,
      );
    }
    _text(canvas, '°C', Offset(r.right + 20, r.bottom + 12));
    for (var p = 0; p <= 100; p += 25) {
      final y = plot.y(p.toDouble());
      canvas.drawLine(Offset(r.left, y), Offset(r.right, y), grid);
      _text(canvas, '$p %', Offset(r.left - 6, y), align: TextAlign.right);
      _text(
        canvas,
        strings.grouped((group.size.maxRpm * p / 100).round()),
        Offset(r.right + 6, y),
      );
    }
    _text(
      canvas,
      'rpm',
      Offset(r.right + 6, r.top - 16),
      color: WeColors.muted,
    );

    canvas.save();
    canvas.clipRect(r.inflate(2));

    // 60-second history: thin trace (temperature × RPM).
    if (live.trace.length > 1) {
      final path = Path();
      for (final (i, s) in live.trace.indexed) {
        final o = Offset(plot.x(s.temp.clamp(0, 100)), plot.y(_pct(s.rpm)));
        i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = WeColors.ok.withValues(alpha: .45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    // Effective curve (with automatic endpoints and the start/stop step).
    final phases = group.phases;
    if (phases.isNotEmpty) {
      final curve = Path();
      for (final (i, ph) in phases.indexed) {
        final o = Offset(plot.x(ph.temp), plot.y(_pct(ph.rpm)));
        i == 0 ? curve.moveTo(o.dx, o.dy) : curve.lineTo(o.dx, o.dy);
      }
      final fill = Path.from(curve)
        ..lineTo(plot.x(phases.last.temp), r.bottom)
        ..lineTo(plot.x(phases.first.temp), r.bottom)
        ..close();
      canvas.drawPath(
        fill,
        Paint()..color = WeColors.accent.withValues(alpha: .10),
      );
      canvas.drawPath(
        curve,
        Paint()
          ..color = WeColors.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // Current temperature.
    final t = live.temp;
    if (t != null) {
      final x = plot.x(t.clamp(0, 100));
      canvas.drawLine(
        Offset(x, r.top),
        Offset(x, r.bottom),
        Paint()
          ..color = WeColors.warn.withValues(alpha: .7)
          ..strokeWidth = 1.5,
      );
    }
    canvas.restore();

    if (t != null && live.tempLabel != null) {
      final x = plot.x(t.clamp(0, 100));
      _text(
        canvas,
        live.tempLabel!,
        Offset(x, r.top - 16),
        color: WeColors.warn,
        align: TextAlign.center,
      );
    }

    // Editable points.
    for (final (i, p) in group.points.indexed) {
      final o = plot.toOffset(p);
      final active = dragging == i;
      canvas.drawCircle(o, active ? 9 : 7, Paint()..color = WeColors.surface);
      canvas.drawCircle(
        o,
        active ? 7 : 5.5,
        Paint()..color = active ? WeColors.accentHover : WeColors.accent,
      );
    }

    // Current RPM and label.
    final rpm = live.rpm;
    if (t != null && rpm != null) {
      final o = Offset(plot.x(t.clamp(0, 100)), plot.y(_pct(rpm)));
      canvas.drawCircle(o, 5, Paint()..color = WeColors.ok);
      canvas.drawCircle(
        o,
        5,
        Paint()
          ..color = WeColors.surface
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      final label = strings.fans.dutyAndRpm(
        live.duty?.toString() ?? '—',
        strings.grouped(rpm.round()),
      );
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: WeColors.text,
            fontSize: 11.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final box = Size(tp.width + 16, tp.height + 8);
      var left = o.dx + 12;
      if (left + box.width > r.right) left = o.dx - 12 - box.width;
      final top = (o.dy - box.height - 10).clamp(r.top, r.bottom - box.height);
      final rect = Rect.fromLTWH(left, top, box.width, box.height);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        Paint()..color = WeColors.surface2,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        Paint()
          ..color = WeColors.border
          ..style = PaintingStyle.stroke,
      );
      tp.paint(canvas, rect.topLeft + const Offset(8, 4));
    }
  }

  @override
  bool shouldRepaint(_FanCurvePainter old) => true;
}
