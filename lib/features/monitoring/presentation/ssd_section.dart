import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/app_strings_scope.dart';
import '../../../core/ui/theme.dart';
import '../../../core/ui/widgets.dart';
import '../../preferences/preferences.dart';
import '../application/monitoring_controller.dart';
import '../domain/metrics.dart';
import '../domain/ssd.dart';
import 'format.dart';
import 'metric_widgets.dart';

/// SSD tool: health and SMART data for each NVMe drive.
class SsdSection extends ConsumerWidget {
  const SsdSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ssds = ref.watch(monitoringProvider.select((s) => s.ssds));
    final readAt = ref.watch(monitoringProvider.select((s) => s.ssdsReadAt));
    final latest = ref.watch(monitoringProvider.select((s) => s.latest));
    final unit = ref.watch(
      preferencesProvider.select((p) => p.temperatureUnit),
    );
    final strings = context.strings;
    final s = strings.monitoring;
    final missingSmart =
        ssds?.where((s) => s.smart == null).toList() ?? const [];
    return WeCard(
      title: s.storage,
      trailing: readAt == null
          ? null
          : Text(
              s.ssdRefreshedAt(_hms(readAt)),
              style: const TextStyle(color: WeColors.muted, fontSize: 12),
            ),
      child: switch (ssds) {
        null => NoReading(s.readingSsds),
        [] => NoReading(s.noNvme),
        _ => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (missingSmart.isNotEmpty) _SmartBanner(missingSmart),
            for (final (i, ssd) in ssds.indexed) ...[
              if (i > 0) const Divider(height: 1),
              _SsdRow(
                ssd,
                liveTemp: latest?[Metrics.ssdTemp(ssd.controller)],
                unit: unit,
              ),
            ],
          ],
        ),
      },
    );
  }
}

String _hms(DateTime t) =>
    [t.hour, t.minute, t.second].map((v) => '$v'.padLeft(2, '0')).join(':');

String ssdErrorText(SsdSmartError e, AppStrings strings) {
  final s = strings.monitoring;
  return switch (e.kind) {
    SsdErrorKind.helperMissing => s.ssdHelperMissing,
    SsdErrorKind.helperFailed => s.ssdHelperFailed(e.message ?? ''),
    SsdErrorKind.helperExit => s.ssdHelperExit(e.exitCode ?? 0, e.stderr ?? ''),
    SsdErrorKind.invalidResponse => s.ssdInvalidResponse,
    SsdErrorKind.device => e.message ?? '',
  };
}

class _SmartBanner extends StatelessWidget {
  const _SmartBanner(this.ssds);
  final List<SsdInfo> ssds;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final reasons = {
      for (final s in ssds)
        if (s.smartError case final e?) ssdErrorText(e, strings),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: WeSizes.unit * 1.5),
      padding: const EdgeInsets.all(WeSizes.unit * 1.5),
      decoration: BoxDecoration(
        color: WeColors.warn.withValues(alpha: .1),
        border: Border.all(color: WeColors.warn.withValues(alpha: .4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: WeColors.warn, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(strings.monitoring.smartUnavailable),
                const SizedBox(height: 2),
                Text(
                  reasons.join(' · '),
                  style: const TextStyle(color: WeColors.muted, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SsdRow extends StatelessWidget {
  const _SsdRow(this.ssd, {required this.liveTemp, required this.unit});
  final SsdInfo ssd;
  final double? liveTemp;
  final TemperatureUnit unit;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final s = strings.monitoring;
    final smart = ssd.smart;
    final health = smart?.health;
    final ident = [
      ssd.controller,
      if (ssd.capacityBytes case final c?) formatStorage(c, strings),
      if (ssd.firmware.isNotEmpty) 'fw ${ssd.firmware}',
      if (ssd.serial.isNotEmpty) 'S/N ${ssd.serial}',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: WeSizes.unit * 1.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.save_outlined, color: WeColors.muted, size: 22),
              const SizedBox(width: WeSizes.unit * 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ssd.model,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ident,
                      style: const TextStyle(
                        color: WeColors.muted,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: WeSizes.unit * 2),
              health == null
                  ? StatusPill(label: s.noSmart, color: WeColors.muted)
                  : StatusPill(
                      label: healthLabel(health, strings),
                      color: healthColor(health),
                    ),
              const SizedBox(width: WeSizes.unit * 1.5),
              OutlinedButton(
                onPressed: smart == null
                    ? null
                    : () => showSmartDetails(context, ssd, unit),
                child: Text(strings.common.details),
              ),
            ],
          ),
          const SizedBox(height: WeSizes.unit * 1.5),
          Padding(
            padding: const EdgeInsets.only(left: 22 + WeSizes.unit * 2),
            child: Wrap(
              spacing: WeSizes.unit * 4,
              runSpacing: WeSizes.unit * 1.5,
              children: [
                if (smart != null) _LifeTile(smart),
                _tile(
                  s.temperature,
                  formatTemp(liveTemp ?? smart?.compositeCelsius, unit),
                ),
                if (smart != null) ...[
                  _tile(
                    s.powerOnHours,
                    '${strings.grouped(smart.powerOnHours)} h',
                  ),
                  _tile(s.written, formatStorage(smart.bytesWritten, strings)),
                  _tile(s.read, formatStorage(smart.bytesRead, strings)),
                  _tile(s.powerCycles, strings.grouped(smart.powerCycles)),
                  _tile(
                    s.unsafeShutdowns,
                    strings.grouped(smart.unsafeShutdowns),
                  ),
                  _tile(
                    s.mediaErrors,
                    strings.grouped(smart.mediaErrors),
                    color: smart.mediaErrors > 0 ? WeColors.danger : null,
                  ),
                  _tile(
                    s.availableSpare,
                    '${smart.availableSpare} %',
                    color: smart.availableSpare <= smart.availableSpareThreshold
                        ? WeColors.danger
                        : null,
                  ),
                  _tile(
                    s.criticalWarning,
                    smart.warnings.isEmpty
                        ? strings.common.none
                        : smart.warnings.map(s.smartWarning).join(', '),
                    color: smart.warnings.isEmpty ? null : WeColors.danger,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _tile(String label, String value, {Color? color}) =>
      ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(color: WeColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      );
}

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
            color: healthColor(smart.health),
          ),
        ),
      ],
    ),
  );
}

Color healthColor(SsdHealth h) => switch (h) {
  SsdHealth.good => WeColors.ok,
  SsdHealth.caution => WeColors.warn,
  SsdHealth.bad => WeColors.danger,
};

/// Full SMART table for an SSD.
Future<void> showSmartDetails(
  BuildContext context,
  SsdInfo ssd,
  TemperatureUnit unit,
) {
  final strings = context.strings;
  final s = strings.monitoring;
  final smart = ssd.smart!;
  String kelvin(int k) => formatTemp(k - 273.15, unit);
  final rows = <(String, String)>[
    (
      s.criticalWarning,
      '0x${smart.criticalWarning.toRadixString(16).padLeft(2, '0').toUpperCase()}'
          '${smart.warnings.isEmpty ? '' : ' (${smart.warnings.map(s.smartWarning).join(', ')})'}',
    ),
    (s.compositeTemperature, kelvin(smart.compositeKelvin)),
    (s.availableSpare, '${smart.availableSpare} %'),
    (s.spareThreshold, '${smart.availableSpareThreshold} %'),
    (s.percentageUsed, '${smart.percentageUsed} %'),
    (
      s.remainingLife,
      '${smart.lifeRemaining} % (${healthLabel(smart.health, strings)})',
    ),
    (
      s.dataUnitsRead,
      '${strings.grouped(smart.dataUnitsRead)} '
          '(${formatStorage(smart.bytesRead, strings)})',
    ),
    (
      s.dataUnitsWritten,
      '${strings.grouped(smart.dataUnitsWritten)} '
          '(${formatStorage(smart.bytesWritten, strings)})',
    ),
    (s.hostReadCommands, strings.grouped(smart.hostReadCommands)),
    (s.hostWriteCommands, strings.grouped(smart.hostWriteCommands)),
    (s.controllerBusy, '${strings.grouped(smart.controllerBusyMinutes)} min'),
    (s.powerCycles, strings.grouped(smart.powerCycles)),
    (s.powerOnHours, '${strings.grouped(smart.powerOnHours)} h'),
    (s.unsafeShutdowns, strings.grouped(smart.unsafeShutdowns)),
    (s.mediaErrorsAndIntegrity, strings.grouped(smart.mediaErrors)),
    (s.errorLogEntries, strings.grouped(smart.errorLogEntries)),
    (s.warningTempTime, '${strings.grouped(smart.warningTempMinutes)} min'),
    (s.criticalTempTime, '${strings.grouped(smart.criticalTempMinutes)} min'),
    for (final (i, k) in smart.sensorsKelvin.indexed)
      if (k != 0) (s.sensorTemperature(i + 1), kelvin(k)),
  ];
  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: WeColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WeSizes.radius),
        side: const BorderSide(color: WeColors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(WeSizes.unit * 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ssd.model,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${ssd.controller} · ${s.smartDialogSubtitle}',
                style: const TextStyle(color: WeColors.muted, fontSize: 12.5),
              ),
              const SizedBox(height: WeSizes.unit * 2),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (final (i, (label, value)) in rows.indexed)
                        Container(
                          color: i.isEven
                              ? WeColors.surface2.withValues(alpha: .5)
                              : null,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  label,
                                  style: const TextStyle(color: WeColors.muted),
                                ),
                              ),
                              SelectableText(
                                value,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: WeSizes.unit * 2),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(strings.common.close),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
