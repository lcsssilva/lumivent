part of 'devices_card.dart';

class _ConflictBanner extends StatelessWidget {
  const _ConflictBanner(this.programs);
  final List<String> programs;

  @override
  Widget build(BuildContext context) {
    final s = context.strings.devices;
    return Container(
      margin: const EdgeInsets.only(bottom: WeSizes.unit * 1.5),
      padding: const EdgeInsets.all(WeSizes.unit * 1.5),
      decoration: BoxDecoration(
        color: WeColors.warn.withValues(alpha: .1),
        border: Border.all(color: WeColors.warn.withValues(alpha: .4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: WeColors.warn,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              s.conflicts(
                programs.join(s.joinedBy),
                plural: programs.length > 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
