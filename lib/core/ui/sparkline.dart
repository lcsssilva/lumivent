import 'package:flutter/material.dart';

import 'we_colors.dart';

part 'sparkline_painter.dart';

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
