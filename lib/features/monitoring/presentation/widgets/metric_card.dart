import 'package:flutter/material.dart';

import '../../../../core/i18n/app_strings_scope.dart';
import '../../../../core/ui/sparkline.dart';
import '../../../../core/ui/we_colors.dart';
import '../../../../core/ui/we_sizes.dart';
import '../../../../core/ui/we_card.dart';
import 'stat_grid.dart';

/// Area card (CPU, GPU…): large primary value with 5-minute history below and
/// a grid of secondary values.
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.title,
    required this.icon,
    this.headline,
    this.caption,
    this.series,
    this.seriesMin,
    this.seriesMax,
    this.seriesLabel,
    this.color = WeColors.accent,
    this.stats = const [],
    this.statColumns = 3,
    this.footer,
  });

  final String title;
  final IconData icon;
  final String? headline;
  final String? caption;
  final List<double?>? series;
  final double? seriesMin, seriesMax;

  /// Converts a history value to text (for min/max labels).
  final String Function(double)? seriesLabel;
  final Color color;
  final List<Widget> stats;
  final int statColumns;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final present = series?.whereType<double>().toList() ?? const <double>[];
    return WeCard(
      title: title,
      trailing: Icon(icon, size: 20, color: WeColors.muted),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (headline != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  headline!,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                ),
                if (caption != null) ...[
                  const SizedBox(width: WeSizes.unit),
                  Flexible(
                    child: Text(
                      caption!,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: WeColors.muted,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          if (series != null) ...[
            const SizedBox(height: WeSizes.unit * 1.5),
            Sparkline(
              values: series!,
              height: 56,
              min: seriesMin,
              max: seriesMax,
              color: color,
            ),
            const SizedBox(height: 4),
            Text(
              present.isEmpty || seriesLabel == null
                  ? context.strings.monitoring.lastFiveMinutes
                  : context.strings.monitoring.lastFiveMinutesRange(
                      seriesLabel!(present.reduce((a, b) => a < b ? a : b)),
                      seriesLabel!(present.reduce((a, b) => a > b ? a : b)),
                    ),
              style: const TextStyle(color: WeColors.muted, fontSize: 11.5),
            ),
          ],
          if (stats.isNotEmpty) ...[
            const SizedBox(height: WeSizes.unit * 2),
            const Divider(height: 1),
            const SizedBox(height: WeSizes.unit * 2),
            StatGrid(columns: statColumns, children: stats),
          ],
          ?footer,
        ],
      ),
    );
  }
}
