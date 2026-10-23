import 'package:flutter/material.dart';

import '../../../../core/ui/we_colors.dart';
import '../../../../core/ui/we_sizes.dart';
import '../../../preferences/preferences.dart';
import '../../domain/metrics.dart';
import '../sensor_format.dart';
import '../../domain/sensor_sample.dart';

/// "CPU 52 °C · GPU 44 °C" in the top bar on every page.
class TopbarSensors extends StatelessWidget {
  const TopbarSensors({super.key, required this.latest, required this.unit});

  /// Latest sensor reading, `null` before the first one.
  final SensorSample? latest;
  final TemperatureUnit unit;

  @override
  Widget build(BuildContext context) {
    final latest = this.latest;
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
