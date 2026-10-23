import 'package:flutter/material.dart';

import '../../../../core/i18n/app_strings_scope.dart';
import '../../../../core/ui/we_colors.dart';
import '../../../../core/ui/we_sizes.dart';
import '../../../../core/ui/status_pill.dart';
import '../../domain/device.dart';
import '../../domain/device_info.dart';
import '../device_status_ui.dart';

class DeviceRow extends StatelessWidget {
  const DeviceRow(this.device, {super.key});
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
