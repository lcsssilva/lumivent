import 'package:flutter/material.dart';

import '../../../../core/ui/status_dot.dart';
import '../../../../core/ui/we_colors.dart';
import '../../../../core/ui/we_sizes.dart';

/// Subtle text shown when an area has no reading.
class NoReading extends StatelessWidget {
  const NoReading(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: WeSizes.unit),
    child: Row(
      children: [
        const StatusDot(WeColors.muted, size: 6),
        const SizedBox(width: WeSizes.unit),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: WeColors.muted, fontSize: 12.5),
          ),
        ),
      ],
    ),
  );
}
