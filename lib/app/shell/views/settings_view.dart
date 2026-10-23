import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/we_sizes.dart';
import '../../../features/devices/devices.dart';
import '../../../features/preferences/preferences.dart';
import '../../../features/system/system.dart';
import '../view_models/settings_view_model.dart';
import '../widgets/about_card.dart';
import '../widgets/config_transfer_card.dart';

/// Settings page: composes the public cards from each module.
class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = ref.watch(settingsViewModelProvider);
    final viewModel = ref.read(settingsViewModelProvider.notifier);
    const gap = SizedBox(height: WeSizes.unit * 2);
    return ListView(
      padding: const EdgeInsets.all(WeSizes.unit * 3),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StartupCard(
                  autostart: ui.autostart,
                  location: ui.autostartLocation,
                  onChanged: viewModel.setAutostart,
                ),
                gap,
                PreferencesCard(
                  preferences: ui.preferences,
                  trayAvailable: ui.trayAvailable,
                  onChanged: viewModel.changePreferences,
                ),
                gap,
                ConfigTransferCard(
                  exportConfiguration: viewModel.exportConfiguration,
                  importConfiguration: viewModel.importConfiguration,
                ),
                gap,
                DevicesCard(
                  snapshot: ui.devices,
                  onRescan: viewModel.rescanDevices,
                ),
                gap,
                DiagnosticsCard(checks: ui.checks),
                gap,
                const AboutCard(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
