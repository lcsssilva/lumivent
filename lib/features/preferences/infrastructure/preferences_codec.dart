// JSON codec for the preferences section.
//
// Reading tolerates missing, unknown, or wrongly typed keys: each invalid
// field falls back to its default, so an old or manually edited configuration
// never prevents the app from opening.

import '../../../core/persistence/config_store.dart';
import '../domain/preferences.dart';

Preferences decodePreferences(JsonMap json) {
  const defaults = Preferences();
  T pick<T>(String key, T fallback) {
    final value = json[key];
    return value is T ? value : fallback;
  }

  final fps = pick<int>('effectsFps', defaults.effectsFps);
  return Preferences(
    closeToTray: pick('closeToTray', defaults.closeToTray),
    temperatureUnit:
        TemperatureUnit.values
            .where((u) => u.name == json['temperatureUnit'])
            .firstOrNull ??
        defaults.temperatureUnit,
    effectsFps: Preferences.fpsOptions.contains(fps)
        ? fps
        : defaults.effectsFps,
    language:
        AppLanguage.values
            .where((l) => l.name == json['language'])
            .firstOrNull ??
        defaults.language,
  );
}

JsonMap encodePreferences(Preferences preferences) => {
  'closeToTray': preferences.closeToTray,
  'temperatureUnit': preferences.temperatureUnit.name,
  'effectsFps': preferences.effectsFps,
  'language': preferences.language.name,
};
