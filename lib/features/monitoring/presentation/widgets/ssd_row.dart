import 'package:flutter/material.dart';

import '../../../../core/i18n/app_strings_scope.dart';
import '../../../../core/ui/status_pill.dart';
import '../../../../core/ui/we_colors.dart';
import '../../../../core/ui/we_sizes.dart';
import '../../../preferences/preferences.dart';
import '../../domain/ssd_info.dart';
import '../sensor_format.dart';
import '../ssd_health_color.dart';
import 'ssd_smart_dialog.dart';
import 'ssd_life_tile.dart';

/// One NVMe drive in the storage card: identity, health and SMART tiles.
class SsdRow extends StatelessWidget {
  const SsdRow(
    this.ssd, {
    super.key,
    required this.liveTemp,
    required this.unit,
  });
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
      if (ssd.capacityBytes case final capacity?)
        formatStorage(capacity, strings),
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
                      color: ssdHealthColor(health),
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
                if (smart != null) SsdLifeTile(smart),
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
