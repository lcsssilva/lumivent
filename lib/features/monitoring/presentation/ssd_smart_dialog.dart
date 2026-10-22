import 'package:flutter/material.dart';

import '../../../core/i18n/app_strings_scope.dart';
import '../../../core/ui/theme.dart';
import '../../preferences/preferences.dart';
import '../domain/ssd.dart';
import 'format.dart';

/// Full SMART table for an SSD.
Future<void> showSmartDetails(
  BuildContext context,
  SsdInfo ssd,
  TemperatureUnit unit,
) {
  final strings = context.strings;
  final s = strings.monitoring;
  final smart = ssd.smart!;
  String kelvin(int temperature) => formatTemp(temperature - 273.15, unit);
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
    for (final (index, temperature) in smart.sensorsKelvin.indexed)
      if (temperature != 0)
        (s.sensorTemperature(index + 1), kelvin(temperature)),
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
                      for (final (index, (label, value)) in rows.indexed)
                        Container(
                          color: index.isEven
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
