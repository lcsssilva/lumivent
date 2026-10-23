part of 'fan_curve_editor.dart';

class _FanCurveEditorState extends State<FanCurveEditor> {
  static const _hitRadius = 14.0;
  static const _minGap = 1.0;

  int? _dragging;
  Offset _doubleTapAt = Offset.zero;

  bool get _fixed => widget.group.preset == FanPreset.fixed;

  int? _hit(_FanCurvePlot plot, Offset p) {
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

  void _move(_FanCurvePlot plot, int index, Offset p) {
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

  void _add(_FanCurvePlot plot, Offset p) {
    if (_fixed) return;
    final pts = [...widget.group.points];
    if (pts.length >= FanPresets.maxPoints || _hit(plot, p) != null) return;
    final temp = plot.tempAt(p.dx).roundToDouble();
    if (pts.any((e) => (e.temp - temp).abs() < _minGap)) return;
    pts.add(FanPoint(temp, plot.percentAt(p.dy).roundToDouble()));
    widget.onChanged(widget.group.withPoints(pts));
    widget.onCommit();
  }

  void _remove(_FanCurvePlot plot, Offset p) {
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
        final plot = _FanCurvePlot(Size(c.maxWidth, widget.height));
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
            painter: _FanCurvePainter(
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
