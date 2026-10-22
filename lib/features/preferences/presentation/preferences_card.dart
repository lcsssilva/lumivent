import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_strings_scope.dart';
import '../../../core/ui/we_card.dart';
import '../../../core/ui/setting_row.dart';
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
    final s = context.strings.settings;
    return WeCard(
      title: s.preferences,
      child: Column(
        children: [
          SettingRow(
            title: s.language,
            subtitle: Text(s.languageHint),
            control: SegmentedButton<AppLanguage>(
              key: const ValueKey('language'),
              showSelectedIcon: false,
              // Endonyms: someone who landed in the wrong language can find the
              // way back without reading the current one.
              segments: const [
                ButtonSegment(value: AppLanguage.en, label: Text('English')),
                ButtonSegment(value: AppLanguage.pt, label: Text('Português')),
              ],
              selected: {prefs.language},
              onSelectionChanged: (v) =>
                  ctrl.change((p) => p.copyWith(language: v.first)),
            ),
          ),
          const Divider(height: 16),
          SettingRow(
            title: s.keepInTray,
            subtitle: Text(
              trayAvailable ? s.keepInTrayHint : s.keepInTrayUnavailable,
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
            title: s.temperatureUnit,
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
            title: s.effectsFps,
            subtitle: Text(s.effectsFpsHint),
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
