import 'package:flutter/material.dart';

import 'we_colors.dart';
import 'we_sizes.dart';

/// Settings row: label and description on the left, control on the right.
class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.control,
  });
  final String title;
  final Widget? subtitle;
  final Widget control;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: WeSizes.unit),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                DefaultTextStyle.merge(
                  style: const TextStyle(color: WeColors.muted, fontSize: 12.5),
                  child: subtitle!,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: WeSizes.unit * 2),
        control,
      ],
    ),
  );
}
