import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/app_strings.dart';
import '../../../../core/i18n/app_strings_scope.dart';
import '../../../../core/ui/we_colors.dart';
import '../../../../core/ui/we_sizes.dart';
import '../../../../core/ui/we_card.dart';
import '../../../preferences/preferences.dart';
import '../../application/monitoring_notifier.dart';
import '../../domain/metrics.dart';
import '../../domain/ssd.dart';
import '../../domain/ssd_smart_error.dart';
import '../../domain/ssd_info.dart';
import 'no_reading.dart';
import 'ssd_row.dart';

part 'smart_banner.dart';

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
        ssds?.where((ssd) => ssd.smart == null).toList() ?? const [];
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
            for (final (index, ssd) in ssds.indexed) ...[
              if (index > 0) const Divider(height: 1),
              SsdRow(
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

String _hms(DateTime time) => [
  time.hour,
  time.minute,
  time.second,
].map((value) => '$value'.padLeft(2, '0')).join(':');

String ssdErrorText(SsdSmartError error, AppStrings strings) {
  final s = strings.monitoring;
  return switch (error.kind) {
    SsdErrorKind.helperMissing => s.ssdHelperMissing,
    SsdErrorKind.helperFailed => s.ssdHelperFailed(error.message ?? ''),
    SsdErrorKind.helperExit => s.ssdHelperExit(
      error.exitCode ?? 0,
      error.stderr ?? '',
    ),
    SsdErrorKind.invalidResponse => s.ssdInvalidResponse,
    SsdErrorKind.device => error.message ?? '',
  };
}
