import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_strings_scope.dart';
import '../../../core/ui/theme.dart';
import '../../../core/ui/widgets.dart';
import '../application/devices_controller.dart';
import '../domain/device.dart';
import 'device_status_ui.dart';

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

class _ConflictBanner extends StatelessWidget {
  const _ConflictBanner(this.programs);
  final List<String> programs;

  @override
  Widget build(BuildContext context) {
    final s = context.strings.devices;
    return Container(
      margin: const EdgeInsets.only(bottom: WeSizes.unit * 1.5),
      padding: const EdgeInsets.all(WeSizes.unit * 1.5),
      decoration: BoxDecoration(
        color: WeColors.warn.withValues(alpha: .1),
        border: Border.all(color: WeColors.warn.withValues(alpha: .4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: WeColors.warn,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              s.conflicts(
                programs.join(s.joinedBy),
                plural: programs.length > 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow(this.device);
  final DeviceInfo device;

  @override
  Widget build(BuildContext context) {
    final d = device;
    final strings = context.strings;
    final issue = deviceIssue(d, strings);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: WeSizes.unit * 1.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon(d.kind), color: WeColors.muted, size: 22),
          const SizedBox(width: WeSizes.unit * 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deviceName(d, strings),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  d.model,
                  style: const TextStyle(color: WeColors.muted, fontSize: 12.5),
                ),
                if (d.detail != null)
                  SelectableText(
                    d.detail!,
                    style: const TextStyle(
                      color: WeColors.muted,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                if (issue != null && d.status != DeviceStatus.ok)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      issue,
                      style: TextStyle(color: d.status.color, fontSize: 12.5),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: WeSizes.unit * 2),
          StatusPill(label: d.status.label(strings), color: d.status.color),
        ],
      ),
    );
  }

  static IconData _icon(DeviceKind kind) => switch (kind) {
    DeviceKind.fans => Icons.toys_outlined,
    DeviceKind.motherboard => Icons.developer_board_outlined,
    DeviceKind.memory => Icons.memory_outlined,
    DeviceKind.gpu => Icons.videogame_asset_outlined,
  };
}
