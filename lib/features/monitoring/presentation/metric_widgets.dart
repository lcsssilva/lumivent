import 'package:flutter/material.dart';

import '../../../core/ui/sparkline.dart';
import '../../../core/ui/theme.dart';
import '../../../core/ui/widgets.dart';

/// A small value with a label and, optionally, its own history.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.series,
    this.min,
    this.max,
    this.color = WeColors.accent,
  });

  final String label;
  final String value;
  final List<double?>? series;
  final double? min, max;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: WeColors.muted, fontSize: 12),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      if (series != null) ...[
        const SizedBox(height: 4),
        Sparkline(
          values: series!,
          height: 22,
          min: min,
          max: max,
          color: color,
        ),
      ],
    ],
  );
}

/// Grid of [StatTile]s with [columns] columns.
class StatGrid extends StatelessWidget {
  const StatGrid({super.key, required this.children, this.columns = 3});
  final List<Widget> children;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      if (i > 0) rows.add(const SizedBox(height: WeSizes.unit * 2));
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var j = i; j < i + columns; j++) ...[
              if (j > i) const SizedBox(width: WeSizes.unit * 2),
              Expanded(
                child: j < children.length ? children[j] : const SizedBox(),
              ),
            ],
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

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
                  ? 'últimos 5 min'
                  : 'últimos 5 min · mín ${seriesLabel!(present.reduce((a, b) => a < b ? a : b))}'
                        ' · máx ${seriesLabel!(present.reduce((a, b) => a > b ? a : b))}',
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

/// Subtle text shown when an area has no reading.
class NoReading extends StatelessWidget {
  const NoReading(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: WeSizes.unit),
    child: Row(
      children: [
        const StatusDot(WeColors.muted, size: 6),
        const SizedBox(width: WeSizes.unit),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: WeColors.muted, fontSize: 12.5),
          ),
        ),
      ],
    ),
  );
}
