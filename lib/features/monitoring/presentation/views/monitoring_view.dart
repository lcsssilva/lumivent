import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/app_strings.dart';
import '../../../../core/i18n/app_strings_scope.dart';
import '../../../../core/ui/we_colors.dart';
import '../../../../core/ui/we_sizes.dart';
import '../view_models/monitoring_view_model.dart';
import '../../domain/gpu_fan.dart';
import '../../domain/metrics.dart';
import '../sensor_format.dart';
import '../widgets/metric_card.dart';
import '../widgets/no_reading.dart';
import '../widgets/ssd_section.dart';
import '../widgets/stat_grid.dart';
import '../widgets/stat_tile.dart';
import '../widgets/monitoring_subtitle.dart';

class MonitoringView extends ConsumerWidget {
  const MonitoringView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = ref.watch(monitoringViewModelProvider);
    final strings = context.strings;
    return LayoutBuilder(
      builder: (context, box) {
        final cols = box.maxWidth >= 1100
            ? 3
            : box.maxWidth >= 720
            ? 2
            : 1;
        final cpu = (_cpu(v, strings), 1),
            gpu = (_gpu(v, strings), 1),
            mem = (_memory(v, strings), 1);
        final board = (_board(v, strings, cols), cols >= 2 ? 2 : 1),
            fans = (_alv2(v, strings), 1);
        final cards = cols == 2
            ? [cpu, gpu, mem, fans, board]
            : [cpu, gpu, mem, board, fans];
        const pad = WeSizes.unit * 3;
        // Fill the area: the shell's AnimatedSwitcher would otherwise center the page.
        return SizedBox.expand(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(pad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ..._rows(cards, cols, box.maxWidth - 2 * pad),
                const SizedBox(height: WeSizes.unit * 2),
                const SsdSection(),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Distributes cards into rows of [cols] aligned columns, with the same height
  /// within each row.
  static List<Widget> _rows(List<(Widget, int)> cards, int cols, double width) {
    const gap = WeSizes.unit * 2;
    final unit = (width - gap * (cols - 1)) / cols;
    final rows = <List<(Widget, int)>>[[]];
    var used = 0;
    for (final c in cards) {
      if (used + c.$2 > cols) {
        rows.add([]);
        used = 0;
      }
      rows.last.add(c);
      used += c.$2;
    }
    return [
      for (final (i, row) in rows.indexed) ...[
        if (i > 0) const SizedBox(height: gap),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (j, (card, span)) in row.indexed) ...[
                if (j > 0) const SizedBox(width: gap),
                SizedBox(width: unit * span + gap * (span - 1), child: card),
              ],
            ],
          ),
        ),
      ],
    ];
  }

  Widget _cpu(MonitoringViewModel v, AppStrings strings) {
    final s = strings.monitoring;
    return MetricCard(
      title: 'CPU',
      icon: Icons.memory_outlined,
      headline: v.temp(Metrics.cpuTctl),
      caption: 'Tctl',
      series: v.history.series(Metrics.cpuTctl),
      seriesLabel: v.tempLabel,
      color: WeColors.accent,
      stats: [
        StatTile(label: 'CCD 1', value: v.temp(Metrics.cpuTccd1)),
        StatTile(
          label: s.averageClock,
          value: v.metric(Metrics.cpuClock, MetricUnit.megahertz, strings),
        ),
        StatTile(
          label: s.usage,
          value: v.metric(Metrics.cpuUsage, MetricUnit.percent, strings),
          series: v.history.series(Metrics.cpuUsage),
          min: 0,
          max: 100,
        ),
      ],
    );
  }

  Widget _gpu(MonitoringViewModel v, AppStrings strings) {
    final s = strings.monitoring;
    final used = v.now(Metrics.gpuVramUsed),
        total = v.now(Metrics.gpuVramTotal);
    final fan = gpuFanState(
      rpm: v.now(Metrics.gpuFan),
      junction: v.now(Metrics.gpuJunction),
    );
    // The fan controller follows the junction (hotspot), not the edge
    // (`docs/hardware.md`), so the junction is the headline.
    return MetricCard(
      title: s.gpu,
      icon: Icons.videogame_asset_outlined,
      headline: v.temp(Metrics.gpuJunction),
      caption: s.junction,
      series: v.history.series(Metrics.gpuJunction),
      seriesLabel: v.tempLabel,
      color: WeColors.ok,
      stats: [
        StatTile(
          label: s.fan,
          value: switch (fan) {
            GpuFanState.zeroFan => s.fanStoppedZeroFan,
            GpuFanState.stoppedHot => s.fanStoppedHot,
            _ => v.metric(Metrics.gpuFan, MetricUnit.rpm, strings),
          },
          series: v.history.series(Metrics.gpuFan),
          min: 0,
          color: fan == GpuFanState.stoppedHot ? WeColors.danger : WeColors.ok,
        ),
        StatTile(label: s.edge, value: v.temp(Metrics.gpuEdge)),
        StatTile(label: s.memoryLabel, value: v.temp(Metrics.gpuMem)),
        StatTile(
          label: s.usage,
          value: v.metric(Metrics.gpuUsage, MetricUnit.percent, strings),
          series: v.history.series(Metrics.gpuUsage),
          min: 0,
          max: 100,
          color: WeColors.ok,
        ),
        StatTile(
          label: s.clock,
          value: v.metric(Metrics.gpuClock, MetricUnit.megahertz, strings),
        ),
        StatTile(
          label: s.power,
          value: v.metric(Metrics.gpuPower, MetricUnit.watts, strings),
          series: v.history.series(Metrics.gpuPower),
          min: 0,
          color: WeColors.ok,
        ),
        if (used != null && total != null)
          StatTile(
            label: s.vram,
            value:
                '${strings.decimal(used / (1 << 30), 1)} / '
                '${formatGiB(total, strings)}',
          ),
      ],
    );
  }

  Widget _memory(MonitoringViewModel v, AppStrings strings) {
    final s = strings.monitoring;
    final used = v.now(Metrics.memUsed), total = v.now(Metrics.memTotal);
    final percent = [
      for (final s in v.history.samples)
        if (s[Metrics.memUsed] case final u?
            when (s[Metrics.memTotal] ?? 0) > 0)
          u / s[Metrics.memTotal]! * 100
        else
          null,
    ];
    return MetricCard(
      title: s.memory,
      icon: Icons.storage_outlined,
      headline: used == null ? dash : formatGiB(used, strings),
      caption: total == null || used == null
          ? null
          : s.memoryOf(formatGiB(total, strings), (used / total * 100).round()),
      series: percent,
      seriesMin: 0,
      seriesMax: 100,
      seriesLabel: (p) => '${p.round()} %',
      color: WeColors.warn,
      statColumns: 2,
      stats: [
        for (var slot = 1; slot <= 2; slot++)
          StatTile(
            label: s.memoryStick(slot),
            value: v.temp(Metrics.dimmTemp(slot)),
            series: v.history.seen(Metrics.dimmTemp(slot))
                ? v.history.series(Metrics.dimmTemp(slot))
                : null,
            color: WeColors.warn,
          ),
      ],
    );
  }

  Widget _board(MonitoringViewModel v, AppStrings strings, int cols) {
    final s = strings.monitoring;
    final temps = Metrics.boardTemps
        .where((d) => v.history.seen(d.id))
        .toList();
    final fans = Metrics.boardFans
        .where((d) => v.history.everPositive(d.id))
        .toList();
    final columns = cols >= 2 ? 5 : 3;
    return MetricCard(
      title: s.motherboard,
      icon: Icons.developer_board_outlined,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MonitoringSubtitle(s.temperatures),
          if (temps.isEmpty)
            NoReading(s.noBoardSensors)
          else
            StatGrid(
              columns: columns,
              children: [
                for (final d in temps)
                  StatTile(
                    label: s.metricLabel(d.id, d.label),
                    value: v.temp(d.id),
                    series: v.history.series(d.id),
                    color: WeColors.accentHover,
                  ),
              ],
            ),
          const SizedBox(height: WeSizes.unit * 2),
          MonitoringSubtitle(s.fansAndPump),
          if (fans.isEmpty)
            NoReading(s.noFanConnectors)
          else
            StatGrid(
              columns: columns,
              children: [
                for (final d in fans)
                  StatTile(
                    label: s.metricLabel(d.id, d.label),
                    value: v.metric(d.id, MetricUnit.rpm, strings),
                    series: v.history.series(d.id),
                    min: 0,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _alv2(MonitoringViewModel v, AppStrings strings) {
    final s = strings.monitoring;
    // Group 0 is usually empty: show it only when it has RPM.
    final groups = [
      for (var g = 0; g < 4; g++)
        if (g > 0 && v.history.seen(Metrics.alv2Rpm(g)) ||
            v.history.everPositive(Metrics.alv2Rpm(g)))
          g,
    ];
    return MetricCard(
      title: s.alv2Fans,
      icon: Icons.toys_outlined,
      footer: groups.isEmpty
          ? NoReading(s.noAlv2Reading)
          : StatGrid(
              columns: 1,
              children: [
                for (final g in groups)
                  StatTile(
                    label: strings.common.groupName(g),
                    value: v.metric(
                      Metrics.alv2Rpm(g),
                      MetricUnit.rpm,
                      strings,
                    ),
                    series: v.history.series(Metrics.alv2Rpm(g)),
                    min: 0,
                  ),
              ],
            ),
    );
  }
}
