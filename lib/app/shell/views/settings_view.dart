import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/we_sizes.dart';
import '../../../features/devices/devices.dart';
import '../../../features/preferences/preferences.dart';
import '../../../features/system/system.dart';
import '../../desktop/desktop_actions.dart';
import '../widgets/about_card.dart';
import '../widgets/config_transfer_card.dart';

/// Settings page: composes the public cards from each module.
class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trayAvailable = ref.watch(desktopActionsProvider).trayAvailable;
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
                const StartupCard(),
                gap,
                PreferencesCard(trayAvailable: trayAvailable),
                gap,
                const ConfigTransferCard(),
                gap,
                const DevicesCard(),
                gap,
                const DiagnosticsCard(),
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
