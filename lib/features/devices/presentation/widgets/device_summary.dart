import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/app_strings_scope.dart';
import '../../../../core/ui/we_colors.dart';
import '../../../../core/ui/status_dot.dart';
import '../../application/devices_notifier.dart';
import '../../domain/device.dart';
import '../device_status_ui.dart';

/// Compact device status (sidebar footer).
class DeviceSummary extends ConsumerWidget {
  const DeviceSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(devicesProvider);
    final strings = context.strings;
    final s = strings.devices;
    final rows = <(String, DeviceStatus?)>[];
    if (snap == null) {
      rows.add((strings.shell.detecting, null));
    } else {
      for (final kind in DeviceKind.values) {
        final list = snap.ofKind(kind).toList();
        if (list.isEmpty) continue;
        rows.add((
          _kindLabel(kind, list.length),
          worstStatus(list.map((d) => d.status)),
        ));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Text(
            s.devicesHeader,
            style: const TextStyle(
              color: WeColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: .8,
            ),
          ),
        ),
        for (final (label, status) in rows)
          Tooltip(
            message: status?.label(strings) ?? '',
            waitDuration: const Duration(milliseconds: 400),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              child: Row(
                children: [
                  StatusDot(status?.color ?? WeColors.muted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: WeColors.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  static String _kindLabel(DeviceKind kind, int count) => switch (kind) {
    DeviceKind.fans => 'AL V2',
    DeviceKind.motherboard => 'ITE 5702',
    DeviceKind.memory => count > 1 ? 'RAM ×$count' : 'RAM',
    DeviceKind.gpu => 'GPU',
  };
}
