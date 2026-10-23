part of 'ssd_row.dart';

class _LifeTile extends StatelessWidget {
  const _LifeTile(this.smart);
  final NvmeSmartLog smart;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 128,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.strings.monitoring.remainingLife,
          style: const TextStyle(color: WeColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          '${smart.lifeRemaining} %',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: smart.lifeRemaining / 100,
            minHeight: 4,
            backgroundColor: WeColors.surface2,
            color: _healthColor(smart.health),
          ),
        ),
      ],
    ),
  );
}
