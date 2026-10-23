import 'settings_strings.dart';

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
