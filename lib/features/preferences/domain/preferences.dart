// Preferences module domain (pure Dart): general app preferences.
//
// Reading tolerates missing, unknown, or wrongly typed keys: each
// invalid field falls back to its default, so an old or manually edited
// configuration never prevents the app from opening.

enum TemperatureUnit { celsius, fahrenheit }

/// Interface language. English is the default (new installs and old configs).
enum AppLanguage { en, pt }

class Preferences {
  const Preferences({
    this.closeToTray = true,
    this.temperatureUnit = TemperatureUnit.celsius,
    this.effectsFps = 30,
    this.language = AppLanguage.en,
  });

  static const fpsOptions = [15, 30, 60];

  /// Closing the window only hides it; the app remains in the system tray.
  final bool closeToTray;
  final TemperatureUnit temperatureUnit;

  /// Frames per second for the LED loop (the AL V2 is limited to ~15).
  final int effectsFps;

  /// UI language; missing or unknown values fall back to English.
  final AppLanguage language;

  Preferences copyWith({
    bool? closeToTray,
    TemperatureUnit? temperatureUnit,
    int? effectsFps,
    AppLanguage? language,
  }) => Preferences(
    closeToTray: closeToTray ?? this.closeToTray,
    temperatureUnit: temperatureUnit ?? this.temperatureUnit,
    effectsFps: effectsFps ?? this.effectsFps,
    language: language ?? this.language,
  );

  factory Preferences.fromJson(Map<String, Object?> json) {
    const d = Preferences();
    T pick<T>(String key, T fallback) {
      final v = json[key];
      return v is T ? v : fallback;
    }

    final fps = pick<int>('effectsFps', d.effectsFps);
    return Preferences(
      closeToTray: pick('closeToTray', d.closeToTray),
      temperatureUnit:
          TemperatureUnit.values
              .where((u) => u.name == json['temperatureUnit'])
              .firstOrNull ??
          d.temperatureUnit,
      effectsFps: fpsOptions.contains(fps) ? fps : d.effectsFps,
      language:
          AppLanguage.values
              .where((l) => l.name == json['language'])
              .firstOrNull ??
          d.language,
    );
  }

  Map<String, Object?> toJson() => {
    'closeToTray': closeToTray,
    'temperatureUnit': temperatureUnit.name,
    'effectsFps': effectsFps,
    'language': language.name,
  };

  @override
  bool operator ==(Object other) =>
      other is Preferences &&
      other.closeToTray == closeToTray &&
      other.temperatureUnit == temperatureUnit &&
      other.effectsFps == effectsFps &&
      other.language == language;

  @override
  int get hashCode =>
      Object.hash(closeToTray, temperatureUnit, effectsFps, language);
}

/// Persistence port for preferences.
abstract interface class PreferencesRepository {
  Preferences load();
  Future<void> save(Preferences preferences);
}
