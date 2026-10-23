// Right column (hardware mode): motherboard (ITE) effect panel.

import 'package:flutter/material.dart';

import '../../../../core/i18n/app_strings_scope.dart';
import '../../../../core/ui/we_card.dart';
import '../../domain/config/lighting_config.dart';
import '../../domain/config/board_zone_config.dart';
import '../lighting_labels.dart';
import 'panel_slider.dart';
import 'panel_row.dart';
import 'panel_dropdown.dart';
import 'color_swatch_button.dart';

class BoardHardwarePanel extends StatelessWidget {
  const BoardHardwarePanel({
    super.key,
    required this.config,
    required this.onEdit,
  });

  final LightingConfig config;
  final ValueChanged<LightingConfigEdit> onEdit;

  @override
  Widget build(BuildContext context) {
    final cfg = config;
    final strings = context.strings;
    final l = strings.lighting;

    void setZone(int z, BoardZoneConfig Function(BoardZoneConfig) f) =>
        onEdit((c) => c.withBoardZone(z, f));

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
