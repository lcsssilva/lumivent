part of 'effect_card.dart';

class _EffectTag extends StatelessWidget {
  const _EffectTag({required this.text});
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
