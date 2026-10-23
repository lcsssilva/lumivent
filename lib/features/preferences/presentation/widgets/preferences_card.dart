import 'package:flutter/material.dart';

import '../../../../core/i18n/app_strings_scope.dart';
import '../../../../core/ui/we_card.dart';
import '../../../../core/ui/setting_row.dart';
import '../../domain/preferences.dart';

class PreferencesCard extends StatelessWidget {
  const PreferencesCard({
    super.key,
    required this.preferences,
    required this.trayAvailable,
    required this.onChanged,
  });

  final Preferences preferences;

  /// Without a system tray, closing the window exits the app and the option is locked.
  final bool trayAvailable;

  /// Applies a change to the preferences.
  final ValueChanged<Preferences Function(Preferences)> onChanged;

  @override
  Widget build(BuildContext context) {
    final prefs = preferences;
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
                  onChanged((p) => p.copyWith(language: v.first)),
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
                  ? (v) => onChanged((p) => p.copyWith(closeToTray: v))
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
                  onChanged((p) => p.copyWith(temperatureUnit: s.first)),
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
                  onChanged((p) => p.copyWith(effectsFps: s.first)),
            ),
          ),
        ],
      ),
    );
  }
}
