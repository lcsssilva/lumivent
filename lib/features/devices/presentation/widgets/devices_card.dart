import 'package:flutter/material.dart';

import '../../../../core/i18n/app_strings_scope.dart';
import '../../../../core/ui/we_colors.dart';
import '../../../../core/ui/we_sizes.dart';
import '../../../../core/ui/we_card.dart';
import '../../domain/device_snapshot.dart';
import 'device_conflict_banner.dart';
import 'device_row.dart';

/// Complete device list with details, hints, and conflicts.
class DevicesCard extends StatelessWidget {
  const DevicesCard({
    super.key,
    required this.snapshot,
    required this.onRescan,
  });

  /// Last detection, `null` while the first scan runs.
  final DeviceSnapshot? snapshot;
  final VoidCallback onRescan;

  @override
  Widget build(BuildContext context) {
    final snap = snapshot;
    final strings = context.strings;
    final s = strings.devices;
    return WeCard(
      title: s.devices,
      trailing: OutlinedButton.icon(
        icon: const Icon(Icons.refresh, size: 18),
        label: Text(s.detectAgain),
        onPressed: onRescan,
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
                if (snap.conflicts.isNotEmpty)
                  DeviceConflictBanner(snap.conflicts),
                for (final (i, d) in snap.devices.indexed) ...[
                  if (i > 0) const Divider(height: 1),
                  DeviceRow(d),
                ],
              ],
            ),
    );
  }
}
