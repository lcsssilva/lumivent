import 'package:flutter/material.dart';

import '../../../../core/ui/we_colors.dart';

class EffectTag extends StatelessWidget {
  const EffectTag({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: WeColors.surface2,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: WeColors.border),
    ),
    child: Text(
      text,
      style: const TextStyle(color: WeColors.muted, fontSize: 10.5),
    ),
  );
}
