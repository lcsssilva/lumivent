import 'package:flutter/material.dart';

import '../../../../core/i18n/app_strings_scope.dart';
import '../../../../core/ui/we_colors.dart';
import '../../domain/effect_compatibility.dart';
import '../../domain/installed_effect.dart';
import '../lighting_labels.dart';

class EffectSupportLine extends StatelessWidget {
  const EffectSupportLine({super.key, required this.effect});
  final InstalledEffect effect;

  @override
  Widget build(BuildContext context) {
    final color = switch (effect.compatibility.support) {
      EffectSupport.compatible => WeColors.ok,
      EffectSupport.partial => WeColors.warn,
      EffectSupport.unsupported => WeColors.danger,
    };
    final strings = context.strings;
    final l = strings.lighting;
    final label = switch (effect.compatibility.support) {
      EffectSupport.compatible => l.compatible,
      EffectSupport.partial => l.partial,
      EffectSupport.unsupported => l.unsupportedEffect,
    };
    final issues = [
      for (final i in effect.compatibility.issues) effectIssueLabel(strings, i),
    ];
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            issues.isEmpty ? label : '$label: ${issues.join(', ')}',
            style: TextStyle(color: color, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
