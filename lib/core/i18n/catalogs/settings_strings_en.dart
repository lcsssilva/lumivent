import 'settings_strings.dart';

class SettingsStringsEn extends SettingsStrings {
  const SettingsStringsEn();

  @override
  String get preferences => 'Preferences';
  @override
  String get language => 'Language';
  @override
  String get languageHint =>
      'Changes immediately; the choice is saved with the configuration.';
  @override
  String get keepInTray => 'Keep in the system tray when closing';
  @override
  String get keepInTrayHint =>
      'Closing the window only hides it; curves and effects keep running.';
  @override
  String get keepInTrayUnavailable =>
      'The system tray is not available: closing the window quits the app.';
  @override
  String get temperatureUnit => 'Temperature unit';
  @override
  String get effectsFps => 'Effect frames per second';
  @override
  String get effectsFpsHint => 'The AL V2 hub accepts at most ~15 FPS.';
  @override
  String get startup => 'Startup';
  @override
  String get startAtLogin => 'Start at login';
  @override
  String systemdUnit(String location) =>
      'systemd --user unit, starts minimized in the tray: $location';
  @override
  String get staleUnit =>
      'The installed unit points to another executable. Disable and enable it '
      'again to use this one.';
  @override
  String get permissionsAndSystem => 'Permissions and system';
}
