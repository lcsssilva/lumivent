import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/app_strings_scope.dart';
import '../../../core/ui/theme.dart';
import '../domain/fan_curve.dart';
import '../domain/fan_group.dart';

/// Live data the editor draws on top of the curve.
class FanCurveLive {
  const FanCurveLive({
    this.temp,
    this.rpm,
    this.duty,
    this.tempLabel,
    this.trace = const [],
  });

  /// Current source temperature, in °C.
  final double? temp;

  /// Current group RPM.
  final double? rpm;

  /// Duty sent during the last cycle.
  final int? duty;

  /// Temperature already formatted in the user's unit (°C/°F).
  final String? tempLabel;

  /// Last ~60 seconds as pairs (°C, RPM). Missing readings are excluded.
  final List<({double temp, double rpm})> trace;
}

/// Curve editor: X = 0–100 °C, Y = 0–100% (secondary axis in RPM).
///
/// Dragging moves a point (X stays between its neighbors), double-clicking empty
/// space adds a point, and right-clicking a point removes it. Fixed mode only
/// allows vertical dragging of its single point.
class FanCurveEditor extends StatefulWidget {
  const FanCurveEditor({
    super.key,
    required this.group,
    required this.live,
    required this.onChanged,
    required this.onCommit,
    this.height = 320,
  });

  final FanGroupConfig group;
  final FanCurveLive live;

  /// Called for every point change (while dragging, without saving).
  final ValueChanged<FanGroupConfig> onChanged;

  /// End of an edit: save now.
  final VoidCallback onCommit;
  final double height;

  @override
  State<FanCurveEditor> createState() => _FanCurveEditorState();
}

class _FanCurveEditorState extends State<FanCurveEditor> {
  static const _hitRadius = 14.0;
  static const _minGap = 1.0;

  int? _dragging;
  Offset _doubleTapAt = Offset.zero;

  bool get _fixed => widget.group.preset == FanPreset.fixed;

  int? _hit(_Plot plot, Offset p) {
    final pts = widget.group.points;
    int? best;
    var bestDist = _hitRadius;
    for (final (i, pt) in pts.indexed) {
      final d = (plot.toOffset(pt) - p).distance;
      if (d <= bestDist) {
        best = i;
        bestDist = d;
      }
    }
    return best;
  }

  void _move(_Plot plot, int index, Offset p) {
    final pts = [...widget.group.points];
    if (index >= pts.length) return;
    final percent = plot.percentAt(p.dy).roundToDouble();
    var temp = pts[index].temp;
    if (!_fixed) {
      final minTemp = index == 0 ? 0.0 : pts[index - 1].temp + _minGap;
      final maxTemp = index == pts.length - 1
          ? 100.0
          : pts[index + 1].temp - _minGap;
      temp = plot
          .tempAt(p.dx)
          .roundToDouble()
          .clamp(minTemp, math.max(minTemp, maxTemp));
    }
    final next = FanPoint(temp, percent);
    if (next == pts[index]) return;
    pts[index] = next;
    widget.onChanged(widget.group.withPoints(pts));
  }

  void _add(_Plot plot, Offset p) {
    if (_fixed) return;
    final pts = [...widget.group.points];
    if (pts.length >= FanPresets.maxPoints || _hit(plot, p) != null) return;
    final temp = plot.tempAt(p.dx).roundToDouble();
    if (pts.any((e) => (e.temp - temp).abs() < _minGap)) return;
    pts.add(FanPoint(temp, plot.percentAt(p.dy).roundToDouble()));
    widget.onChanged(widget.group.withPoints(pts));
    widget.onCommit();
  }

  void _remove(_Plot plot, Offset p) {
    if (_fixed) return;
    final pts = [...widget.group.points];
    final i = _hit(plot, p);
    if (i == null || pts.length <= 1) return;
    pts.removeAt(i);
    widget.onChanged(widget.group.withPoints(pts));
    widget.onCommit();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: widget.height,
    child: LayoutBuilder(
      builder: (context, c) {
        final plot = _Plot(Size(c.maxWidth, widget.height));
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanDown: (d) => _dragging = _hit(plot, d.localPosition),
          onPanUpdate: (d) {
            final i = _dragging;
            if (i != null) _move(plot, i, d.localPosition);
          },
          onPanEnd: (_) => _endDrag(),
          onPanCancel: _endDrag,
          onDoubleTapDown: (d) => _doubleTapAt = d.localPosition,
          onDoubleTap: () => _add(plot, _doubleTapAt),
          onSecondaryTapDown: (d) => _remove(plot, d.localPosition),
          child: CustomPaint(
            size: Size(c.maxWidth, widget.height),
            painter: _CurvePainter(
              widget.group,
              widget.live,
              plot,
              _dragging,
              context.strings,
            ),
          ),
        );
      },
    ),
  );

  void _endDrag() {
    if (_dragging != null) {
      _dragging = null;
      widget.onCommit();
    }
  }
}

/// Chart area geometry inside the widget.
class _Plot {
  _Plot(Size size)
    : rect = Rect.fromLTRB(
        44,
        26,
        math.max(45, size.width - 64),
        math.max(27, size.height - 28),
      );
  final Rect rect;

  double x(double temp) => rect.left + temp / 100 * rect.width;
  double y(double percent) => rect.bottom - percent / 100 * rect.height;
  Offset toOffset(FanPoint p) => Offset(x(p.temp), y(p.percent));
  double tempAt(double dx) =>
      ((dx - rect.left) / rect.width * 100).clamp(0, 100);
  double percentAt(double dy) =>
      ((rect.bottom - dy) / rect.height * 100).clamp(0, 100);
}

class _CurvePainter extends CustomPainter {
  _CurvePainter(this.group, this.live, this.plot, this.dragging, this.strings);

  final FanGroupConfig group;
  final FanCurveLive live;
  final _Plot plot;
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
  bool shouldRepaint(_CurvePainter old) => true;
}
