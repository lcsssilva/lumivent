import 'package:flutter/material.dart';

import '../../../core/ui/sparkline.dart';
import '../../../core/ui/theme.dart';

/// A small value with a label and, optionally, its own history.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.series,
    this.min,
    this.max,
    this.color = WeColors.accent,
  });

  final String label;
  final String value;
  final List<double?>? series;
  final double? min, max;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: WeColors.muted, fontSize: 12),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      if (series != null) ...[
        const SizedBox(height: 4),
        Sparkline(
          values: series!,
          height: 22,
          min: min,
          max: max,
          color: color,
        ),
      ],
    ],
  );
}
