// Right column (hardware mode): GPU effect panel for the graphics card.

import 'package:flutter/material.dart';

import '../../../../core/i18n/app_strings_scope.dart';
import '../../../../core/ui/we_colors.dart';
import '../../../../core/ui/we_card.dart';
import '../../domain/config/lighting_config.dart';
import '../../domain/hardware_mode/gpu_hardware_config.dart';
import '../lighting_labels.dart';
import 'panel_slider.dart';
import 'panel_row.dart';
import 'panel_dropdown.dart';
import 'color_swatch_button.dart';

class GpuHardwarePanel extends StatelessWidget {
  const GpuHardwarePanel({
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
    final hw = cfg.gpuHardware;
    final colors = [
      for (var i = 0; i < hw.effect.colors; i++)
        i < hw.colors.length
            ? hw.colors[i]
            : GpuHardwareConfig.defaultColors[i %
                  GpuHardwareConfig.defaultColors.length],
    ];

    void setHw(GpuHardwareConfig Function(GpuHardwareConfig) f) =>
        onEdit((c) => c.withGpuHardware(f));

    return WeCard(
      flat: true,
      title: l.hardwareTitle(l.graphicsCard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PanelRow(
            label: l.mode,
            control: PanelDropdown<GpuEffect>(
              key: const ValueKey('gpu-mode'),
              value: hw.effect,
              items: GpuEffect.values,
              labelOf: (e) => gpuEffectLabel(strings, e),
              onChanged: (e) => setHw((h) => h.copyWith(effect: e)),
            ),
          ),
          if (hw.effect.hasSpeed)
            PanelSlider(
              label: l.speed,
              valueText: '${hw.speed}/10',
              value: hw.speed.toDouble(),
              min: 0,
              max: 10,
              divisions: 10,
              onChanged: (v) => setHw((h) => h.copyWith(speed: v.round())),
            ),
          if (hw.effect.hasBrightness)
            PanelSlider(
              label: l.brightness,
              valueText: '${hw.brightness}/10',
              value: hw.brightness.toDouble(),
              min: 0,
              max: 10,
              divisions: 10,
              onChanged: (v) => setHw((h) => h.copyWith(brightness: v.round())),
            ),
          if (hw.effect == GpuEffect.colorShift)
            PanelRow(
              label: l.colorsCount(8),
              control: Wrap(
                spacing: 6,
                children: [
                  for (var i = 0; i < colors.length; i++)
                    ColorSwatchButton(
                      key: ValueKey('gpu-color-$i'),
                      color: colors[i],
                      size: 24,
                      onChanged: (c) => setHw((h) {
                        final next = [...colors];
                        next[i] = c;
                        return h.copyWith(colors: next);
                      }),
                    ),
                ],
              ),
            )
          else if (hw.effect != GpuEffect.off)
            PanelRow(
              label: l.color,
              control: ColorSwatchButton(
                key: const ValueKey('gpu-color'),
                color: hw.color,
                onChanged: (c) => setHw((h) => h.copyWith(color: c)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l.gpuNote,
              style: const TextStyle(color: WeColors.muted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
