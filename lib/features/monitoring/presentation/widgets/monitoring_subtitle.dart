import 'package:flutter/material.dart';

import '../../../../core/ui/we_colors.dart';
import '../../../../core/ui/we_sizes.dart';

class MonitoringSubtitle extends StatelessWidget {
  const MonitoringSubtitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: WeSizes.unit * 1.5),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: WeColors.muted,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: .6,
      ),
    ),
  );
}
