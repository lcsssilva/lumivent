import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/theme.dart';
import '../../preferences/preferences.dart';
import '../application/monitoring_controller.dart';
import '../domain/metrics.dart';
import 'format.dart';

/// "CPU 52 °C · GPU 44 °C" in the top bar on every page.
class TopbarSensors extends ConsumerWidget {
  const TopbarSensors({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latest = ref.watch(monitoringProvider.select((s) => s.latest));
    final unit = ref.watch(
      preferencesProvider.select((p) => p.temperatureUnit),
    );
    final items = [
      ('CPU', latest?[Metrics.cpuTctl]),
      ('GPU', latest?[Metrics.gpuEdge]),
    ].where((e) => e.$2 != null);
    if (items.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, (label, c)) in items.indexed) ...[
          if (i > 0) const SizedBox(width: WeSizes.unit * 2),
          Text(
            label,
            style: const TextStyle(color: WeColors.muted, fontSize: 12.5),
          ),
          const SizedBox(width: 6),
          Text(
            formatTemp(c, unit),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ],
    );
  }
}
