import 'package:flutter/material.dart';

import 'theme.dart';

/// Minimal line chart for short histories. The newest reading is at the right
/// edge; with fewer than [capacity] points the beginning is empty, and `null`
/// creates a gap in the line.
class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.values,
    this.capacity = 300,
    this.color = WeColors.accent,
    this.height = 40,
    this.min,
    this.max,
  });

  final List<double?> values;
  final int capacity;
  final Color color;
  final double height;

  /// Fixed scale (for example, 0–100%). Without it, uses the data range.
  final double? min, max;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: CustomPaint(
      painter: _SparklinePainter(values, capacity, color, min, max),
    ),
  );
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter(this.values, this.capacity, this.color, this.min, this.max);

  final List<double?> values;
  final int capacity;
  final Color color;
  final double? min, max;

  @override
  void paint(Canvas canvas, Size size) {
    final data = values.length > capacity
        ? values.sublist(values.length - capacity)
        : values;
    final present = data.whereType<double>();
    if (present.isEmpty) return;
    var lo = min ?? present.reduce((a, b) => a < b ? a : b);
    var hi = max ?? present.reduce((a, b) => a > b ? a : b);
    if (hi - lo < 1e-9) {
      // Draw a straight line through the middle when the value does not change.
      lo -= 1;
      hi += 1;
    }
    final step = capacity > 1 ? size.width / (capacity - 1) : 0.0;
    final x0 = size.width - (data.length - 1) * step;
    const pad = 2.0;
    double y(double v) =>
        pad +
        (size.height - 2 * pad) * (1 - ((v - lo) / (hi - lo)).clamp(0, 1));

    final line = Path();
    final fill = Path();
    double? runStart;
    double? lastX;
    void closeRun() {
      final start = runStart, end = lastX;
      if (start != null && end != null) {
        fill
          ..lineTo(end, size.height)
          ..lineTo(start, size.height)
          ..close();
      }
      runStart = null;
    }

    for (final (i, v) in data.indexed) {
      final x = x0 + i * step;
      if (v == null) {
        closeRun();
        continue;
      }
      if (runStart == null) {
        runStart = x;
        line.moveTo(x, y(v));
        fill.moveTo(x, y(v));
      } else {
        line.lineTo(x, y(v));
        fill.lineTo(x, y(v));
      }
      lastX = x;
    }
    closeRun();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: .28), color.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      !identical(old.values, values) ||
      old.color != color ||
      old.min != min ||
      old.max != max;
}
