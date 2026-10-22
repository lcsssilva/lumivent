// Right column panel for the selected device / global effect: which hardware
// sub-panel to show depends on the device and the configured mode.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/lighting_controller.dart';
import '../domain/light_device.dart';
import '../domain/lighting_config.dart';
import 'board_hardware_panel.dart';
import 'effect_panel.dart';
import 'fan_hardware_panel.dart';
import 'fixed_color_panel.dart';
import 'gpu_hardware_panel.dart';

class LightingModePanel extends ConsumerWidget {
  const LightingModePanel({super.key, required this.deviceId});

  final LightDeviceId? deviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sel = deviceId;
    if (sel == null) return const EffectPanel();
    final mode = ref.watch(lightingProvider.select((c) => c.device(sel).mode));
    return switch (mode) {
      LightMode.canvas => const EffectPanel(),
      LightMode.fixed => FixedColorPanel(id: sel),
      LightMode.hardware =>
        sel.isFan
            ? FanHardwarePanel(id: sel)
            : sel == LightDeviceId.motherboard
            ? const BoardHardwarePanel()
            : sel == LightDeviceId.gpu
            ? const GpuHardwarePanel()
            : const EffectPanel(),
    };
  }
}
