import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/widgets.dart';
import '../application/preferences_controller.dart';
import '../domain/preferences.dart';

class PreferencesCard extends ConsumerWidget {
  const PreferencesCard({super.key, required this.trayAvailable});

  /// Without a system tray, closing the window exits the app and the option is locked.
  final bool trayAvailable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesProvider);
    final ctrl = ref.read(preferencesProvider.notifier);
    return WeCard(
      title: 'Preferências',
      child: Column(
        children: [
          SettingRow(
            title: 'Manter na bandeja ao fechar',
            subtitle: Text(
              trayAvailable
                  ? 'Fechar a janela apenas a oculta; curvas e efeitos continuam rodando.'
                  : 'A bandeja do sistema não está disponível: fechar a janela encerra o app.',
            ),
            control: Switch(
              value: prefs.closeToTray && trayAvailable,
              onChanged: trayAvailable
                  ? (v) => ctrl.change((p) => p.copyWith(closeToTray: v))
                  : null,
            ),
          ),
          const Divider(height: 16),
          SettingRow(
            title: 'Unidade de temperatura',
            control: SegmentedButton<TemperatureUnit>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: TemperatureUnit.celsius,
                  label: Text('°C'),
                ),
                ButtonSegment(
                  value: TemperatureUnit.fahrenheit,
                  label: Text('°F'),
                ),
              ],
              selected: {prefs.temperatureUnit},
              onSelectionChanged: (s) =>
                  ctrl.change((p) => p.copyWith(temperatureUnit: s.first)),
            ),
          ),
          const Divider(height: 16),
          SettingRow(
            title: 'Quadros por segundo dos efeitos',
            subtitle: const Text(
              'O hub AL V2 aceita no máximo ~15 quadros por segundo.',
            ),
            control: SegmentedButton<int>(
              showSelectedIcon: false,
              segments: [
                for (final fps in Preferences.fpsOptions)
                  ButtonSegment(value: fps, label: Text('$fps')),
              ],
              selected: {prefs.effectsFps},
              onSelectionChanged: (s) =>
                  ctrl.change((p) => p.copyWith(effectsFps: s.first)),
            ),
          ),
        ],
      ),
    );
  }
}
