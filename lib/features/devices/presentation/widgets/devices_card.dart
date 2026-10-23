import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/app_strings_scope.dart';
import '../../../../core/ui/we_colors.dart';
import '../../../../core/ui/we_sizes.dart';
import '../../../../core/ui/status_pill.dart';
import '../../../../core/ui/we_card.dart';
import '../../application/devices_notifier.dart';
import '../../domain/device.dart';
import '../../domain/device_info.dart';
import '../device_status_ui.dart';

part 'conflict_banner.dart';
part 'device_row.dart';

/// Complete device list with details, hints, and conflicts.
class DevicesCard extends ConsumerWidget {
  const DevicesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(devicesProvider);
    final strings = context.strings;
    final s = strings.devices;
    return WeCard(
      title: s.devices,
      trailing: OutlinedButton.icon(
        icon: const Icon(Icons.refresh, size: 18),
        label: Text(s.detectAgain),
        onPressed: () => ref.read(devicesProvider.notifier).rescan(),
      ),
      child: snap == null
          ? Padding(
              padding: const EdgeInsets.all(WeSizes.unit * 2),
              child: Text(
                s.detectingDevices,
                style: const TextStyle(color: WeColors.muted),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (snap.conflicts.isNotEmpty) _ConflictBanner(snap.conflicts),
                for (final (i, d) in snap.devices.indexed) ...[
                  if (i > 0) const Divider(height: 1),
                  _DeviceRow(d),
                ],
              ],
            ),
    );
  }
}
