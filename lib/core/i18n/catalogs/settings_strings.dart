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

class SettingsStringsPt extends SettingsStrings {
  const SettingsStringsPt();

  @override
  String get preferences => 'Preferências';
  @override
  String get language => 'Idioma';
  @override
  String get languageHint =>
      'Muda na hora; a escolha fica salva junto com a configuração.';
  @override
  String get keepInTray => 'Manter na bandeja ao fechar';
  @override
  String get keepInTrayHint =>
      'Fechar a janela apenas a oculta; curvas e efeitos continuam rodando.';
  @override
  String get keepInTrayUnavailable =>
      'A bandeja do sistema não está disponível: fechar a janela encerra o app.';
  @override
  String get temperatureUnit => 'Unidade de temperatura';
  @override
  String get effectsFps => 'Quadros por segundo dos efeitos';
  @override
  String get effectsFpsHint =>
      'O hub AL V2 aceita no máximo ~15 quadros por segundo.';
  @override
  String get startup => 'Inicialização';
  @override
  String get startAtLogin => 'Iniciar com o sistema';
  @override
  String systemdUnit(String location) =>
      'Unidade systemd --user, inicia minimizado na bandeja: $location';
  @override
  String get staleUnit =>
      'A unidade instalada aponta para outro executável. Desative e ative de '
      'novo para usar este.';
  @override
  String get permissionsAndSystem => 'Permissões e sistema';
}
