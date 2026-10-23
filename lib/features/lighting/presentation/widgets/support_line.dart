part of 'effect_panel.dart';

class _SupportLine extends StatelessWidget {
  const _SupportLine({required this.effect});
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
