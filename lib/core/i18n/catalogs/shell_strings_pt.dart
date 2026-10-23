import 'shell_strings.dart';

class ShellStringsPt extends ShellStrings {
  const ShellStringsPt();

  @override
  String get monitoring => 'Monitoramento';
  @override
  String get monitoringSubtitle => 'Sensores da CPU, GPU, placa-mãe e SSDs';
  @override
  String get lighting => 'Iluminação';
  @override
  String get lightingSubtitle =>
      'Efeitos e cores de todos os dispositivos ARGB';
  @override
  String get fans => 'Fans';
  @override
  String get fansSubtitle => 'Velocidade das fans AL V2 por curva ou preset';
  @override
  String get explore => 'Explore';
  @override
  String get exploreSubtitle => 'Biblioteca de efeitos';
  @override
  String get settings => 'Configurações';
  @override
  String get settingsSubtitle => 'Inicialização, preferências e diagnóstico';
  @override
  String get settingsTooltip => 'Configurações';
  @override
  String get devicesHeader => 'DISPOSITIVOS';
  @override
  String get detecting => 'Detectando…';
  @override
  String get hideWindow => 'Ocultar janela';
  @override
  String get showWindow => 'Mostrar janela';
  @override
  String get turnOffAllArgb => 'Desligar todos os ARGB';
  @override
  String get quit => 'Sair';
  @override
  String get about => 'Sobre';
  @override
  String get legalese =>
      'Licença MIT · © 2026 Lucas Silva (lcsssilva)\n'
      'Projeto independente, sem afiliação com os fabricantes do hardware.';
  @override
  String get licenses => 'Licenças…';
  @override
  String get configuration => 'Configuração';
  @override
  String get exportOrImport => 'Exportar ou importar';
  @override
  String get exportOrImportDescription =>
      'Preferências, iluminação e fans num arquivo JSON. Importar aplica na '
      'hora e guarda uma cópia da configuração atual.';
  @override
  String get export => 'Exportar…';
  @override
  String get import => 'Importar…';
  @override
  String get exportDialogTitle => 'Exportar configuração';
  @override
  String get importDialogTitle => 'Importar configuração';
  @override
  String exportedTo(String path) => 'Configuração exportada para $path.';
  @override
  String importedBackupAt(String path) =>
      'Configuração importada e aplicada. A anterior ficou em $path.';
  @override
  String failed(String error) => 'Falha. Detalhes técnicos: $error';
  @override
  String get invalidJson => 'O arquivo não é um JSON válido.';
  @override
  String get notAppConfig => 'O arquivo não é uma configuração do app.';
  @override
  String get newerVersion => 'O arquivo veio de uma versão mais nova do app.';
  @override
  String get noKnownSections =>
      'O arquivo não tem preferências, iluminação nem fans.';
  @override
  String fileTooLarge(int megabytes) =>
      'O arquivo tem mais de $megabytes MB e não é uma configuração.';
  @override
  String get startupFailedTitle => 'O Lumivent não conseguiu iniciar';
  @override
  String get startupFailedHint =>
      'O erro foi escrito no terminal. Confira a configuração ou abra a pasta '
      'dela para corrigir o problema.';
  @override
  String configurationAt(String path) => 'Configuração: $path';
  @override
  String get openConfigurationFolder => 'Abrir pasta de configuração';
  @override
  String openFolderFailed(String error) =>
      'Não foi possível abrir a pasta. Detalhes técnicos: $error';
  @override
  String get underConstruction => 'Em construção';
  @override
  String phase(int phase) => 'Fase $phase';
}
