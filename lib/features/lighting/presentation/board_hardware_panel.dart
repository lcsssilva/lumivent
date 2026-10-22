// Right column (hardware mode): motherboard (ITE) effect panel.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_strings_scope.dart';
import '../../../core/ui/widgets.dart';
import '../application/lighting_controller.dart';
import '../domain/lighting_config.dart';
import 'labels.dart';
import 'panel_controls.dart';

class BoardHardwarePanel extends ConsumerWidget {
  const BoardHardwarePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(lightingProvider);
    final controller = ref.read(lightingProvider.notifier);
    final strings = context.strings;
    final l = strings.lighting;

    void setZone(int z, BoardZoneConfig Function(BoardZoneConfig) f) =>
        controller.update(
          (c) =>
              c.copyWith(boardZones: {...c.boardZones, z: f(c.boardZones[z]!)}),
        );

    return WeCard(
      flat: true,
      title: l.boardHardwareTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final z in boardZoneIds) ...[
            Text(
              boardZoneLabel(strings, z),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            PanelRow(
              label: l.mode,
              control: PanelDropdown<BoardEffectMode>(
                key: ValueKey('board-mode-$z'),
                value: cfg.boardZones[z]!.mode,
                items: BoardEffectMode.values,
                labelOf: (m) => boardModeLabel(strings, m),
                onChanged: (m) => setZone(z, (b) => b.copyWith(mode: m)),
              ),
            ),
            PanelRow(
              label: l.color,
              control: ColorSwatchButton(
                key: ValueKey('board-color-$z'),
                color: cfg.boardZones[z]!.color,
                onChanged: (c) => setZone(z, (b) => b.copyWith(color: c)),
              ),
            ),
            PanelSlider(
              label: l.speed,
              valueText: '${cfg.boardZones[z]!.speed}',
              value: cfg.boardZones[z]!.speed.toDouble(),
              min: 0,
              max: 9,
              divisions: 9,
              onChanged: (v) => setZone(z, (b) => b.copyWith(speed: v.round())),
            ),
            PanelSlider(
              label: l.brightness,
              valueText: '${cfg.boardZones[z]!.brightness}',
              value: cfg.boardZones[z]!.brightness.toDouble(),
              min: 0,
              max: 9,
              divisions: 9,
              onChanged: (v) =>
                  setZone(z, (b) => b.copyWith(brightness: v.round())),
            ),
            if (z != boardZoneIds.last) const Divider(height: 24),
          ],
        ],
      ),
    );
  }
}
