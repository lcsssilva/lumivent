import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/app_strings_scope.dart';
import '../../../core/ui/status_dot.dart';
import '../../../core/ui/theme.dart';
import '../application/lighting_controller.dart';
import '../application/lighting_messages.dart';
import '../domain/hardware_equivalents.dart';
import '../domain/light_device.dart';
import '../domain/lighting_config.dart';
import 'labels.dart';
import 'panel_controls.dart';

/// One lighting device in the horizontal device strip.
class DeviceItem extends ConsumerWidget {
  const DeviceItem({
    super.key,
    required this.id,
    required this.selected,
    required this.onTap,
  });

  final LightDeviceId id;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(lightingProvider.select((c) => c.device(id)));
    final status = ref.watch(
      lightingStatusProvider.select((s) => s?.devices[id]),
    );
    // Canvas device the engine hands to the firmware for the current effect.
    final auto = ref.watch(
      lightingProvider.select((c) => autoHardwareDevices(c).contains(id)),
    );
    final controller = ref.read(lightingProvider.notifier);
    final supported = id.isSupported;
    final strings = context.strings;
    final l = strings.lighting;

    final (Color dot, String tip) = !supported
        ? (WeColors.muted, l.unsupported)
        : switch (status?.state) {
            null => (WeColors.muted, l.waitingStatus),
            LightOutputState.ok => (WeColors.ok, l.working),
            LightOutputState.unavailable => (
              WeColors.danger,
              _outputDetail(strings, status!),
            ),
            LightOutputState.unsupported => (
              WeColors.muted,
              _outputDetail(strings, status!),
            ),
          };

    return Opacity(
      opacity: supported ? 1 : .5,
      child: Container(
        key: ValueKey('device-${id.name}'),
        decoration: BoxDecoration(
          color: selected ? WeColors.accent.withValues(alpha: .12) : null,
          border: Border.all(
            color: selected ? WeColors.accent : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: supported ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Tooltip(
                      message: tip,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: StatusDot(
                          dot,
                          key: ValueKey('status-${id.name}'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        deviceLabel(
                          strings,
                          id,
                          ref.watch(fanGroupNamesProvider),
                        ),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    if (supported)
                      Transform.scale(
                        scale: .8,
                        child: Switch(
                          key: ValueKey('device-switch-${id.name}'),
                          value: cfg.enabled,
                          onChanged: (v) => controller.update(
                            (c) => c.withDevice(id, cfg.copyWith(enabled: v)),
                          ),
                        ),
                      ),
                  ],
                ),
                if (!supported)
                  Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: Text(
                      l.unsupported,
                      style: const TextStyle(
                        color: WeColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  )
                else ...[
                  if (status?.state == LightOutputState.unavailable)
                    Padding(
                      padding: const EdgeInsets.only(left: 24, bottom: 2),
                      child: Text(
                        l.unavailable,
                        style: const TextStyle(
                          color: WeColors.danger,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  if (auto)
                    Padding(
                      padding: const EdgeInsets.only(left: 24, bottom: 2),
                      child: Text(
                        l.autoHardware,
                        key: const Key('auto-badge'),
                        style: const TextStyle(
                          color: WeColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 2),
                  // Full-width dropdown: the strip is narrow, so the mode must
                  // have the whole item width instead of sharing a row.
                  PanelDropdown<LightMode>(
                    key: ValueKey('device-mode-${id.name}'),
                    value: cfg.mode,
                    items: [
                      for (final m in LightMode.values)
                        if (id.accepts(m)) m,
                    ],
                    labelOf: (m) => modeLabel(strings, m),
                    onChanged: (m) {
                      controller.update(
                        (c) => c.withDevice(id, cfg.copyWith(mode: m)),
                      );
                      onTap();
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _outputDetail(AppStrings strings, LightOutputStatus status) {
  final issue = status.issue;
  if (issue == null) {
    return status.state == LightOutputState.unsupported
        ? strings.lighting.unsupported
        : strings.lighting.unavailable;
  }
  return strings.lighting.outputIssue(issue.index, status.args);
}
