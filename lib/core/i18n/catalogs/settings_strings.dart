/// Settings page: preferences, startup, and the diagnostics card title.
abstract class SettingsStrings {
  const SettingsStrings();

  // Preferences.
  String get preferences;
  String get language;
  String get languageHint;
  String get keepInTray;
  String get keepInTrayHint;
  String get keepInTrayUnavailable;
  String get temperatureUnit;
  String get effectsFps;
  String get effectsFpsHint;

  // Startup.
  String get startup;
  String get startAtLogin;
  String systemdUnit(String location);
  String get staleUnit;

  // Diagnostics.
  String get permissionsAndSystem;
}
