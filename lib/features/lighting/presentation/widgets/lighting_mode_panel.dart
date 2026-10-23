// Right column panel for the selected device / global effect: which hardware
// sub-panel to show depends on the device and the configured mode.

import 'package:flutter/material.dart';

import '../../domain/light_device.dart';
import '../../domain/config/lighting_config.dart';
import '../view_models/lighting_ui_state.dart';
import 'board_hardware_panel.dart';
import 'effect_panel.dart';
import 'fan_hardware_panel.dart';
import 'fixed_color_panel.dart';
import 'gpu_hardware_panel.dart';

class LightingModePanel extends StatelessWidget {
  const LightingModePanel({
    super.key,
    required this.ui,
    required this.onEdit,
    required this.onIdentify,
  });

  final LightingUiState ui;
  final ValueChanged<LightingConfigEdit> onEdit;

  /// Pings a hub group (1–3).
  final ValueChanged<int> onIdentify;

  @override
  Widget build(BuildContext context) {
    final config = ui.config;
    final effect = EffectPanel(
      config: config,
      installedLibrary: ui.installedLibrary,
      runnerStatus: ui.runnerStatus,
      onEdit: onEdit,
    );
    final sel = ui.selectedDevice;
    if (sel == null) return effect;
    return switch (config.device(sel).mode) {
      LightMode.canvas => effect,
      LightMode.fixed => FixedColorPanel(
        id: sel,
        config: config,
        fanGroupNames: ui.fanGroupNames,
        onEdit: onEdit,
      ),
      LightMode.hardware =>
        sel.isFan
            ? FanHardwarePanel(
                id: sel,
                config: config,
                fanGroupNames: ui.fanGroupNames,
                modes: ui.fanHardwareModes,
                onEdit: onEdit,
                onIdentify: onIdentify,
              )
            : sel == LightDeviceId.motherboard
            ? BoardHardwarePanel(config: config, onEdit: onEdit)
            : sel == LightDeviceId.gpu
            ? GpuHardwarePanel(config: config, onEdit: onEdit)
            : effect,
    };
  }
}
