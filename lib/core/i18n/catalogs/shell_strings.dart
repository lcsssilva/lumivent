/// Shell strings: navigation, system tray, About/Licenses, and configuration
/// export/import.
abstract class ShellStrings {
  const ShellStrings();

  String get monitoring;
  String get monitoringSubtitle;
  String get lighting;
  String get lightingSubtitle;
  String get fans;
  String get fansSubtitle;
  String get explore;
  String get exploreSubtitle;
  String get settings;
  String get settingsSubtitle;
  String get settingsTooltip;

  /// Sidebar header above the compact device summary.
  String get devicesHeader;
  String get detecting;

  // System tray.
  String get hideWindow;
  String get showWindow;
  String get turnOffAllArgb;
  String get quit;

  // About / licenses.
  String get about;
  String get legalese;
  String get licenses;

  // Configuration export/import.
  String get configuration;
  String get exportOrImport;
  String get exportOrImportDescription;
  String get export;
  String get import;
  String get exportDialogTitle;
  String get importDialogTitle;
  String exportedTo(String path);
  String importedBackupAt(String path);
  String failed(String error);
  String get invalidJson;
  String get notAppConfig;
  String get newerVersion;
  String get noKnownSections;
  String fileTooLarge(int megabytes);

  // Startup failure screen (shown before preferences can be read).
  String get startupFailedTitle;
  String get startupFailedHint;
  String configurationAt(String path);
  String get openConfigurationFolder;
  String openFolderFailed(String error);

  /// Placeholder card title for areas not built yet.
  String get underConstruction;
  String phase(int phase);
}

class ShellStringsEn extends ShellStrings {
  const ShellStringsEn();

  @override
  String get monitoring => 'Monitoring';
  @override
  String get monitoringSubtitle => 'CPU, GPU, motherboard, and SSD sensors';
  @override
  String get lighting => 'Lighting';
  @override
  String get lightingSubtitle => 'Effects and colors for every ARGB device';
  @override
  String get fans => 'Fans';
  @override
  String get fansSubtitle => 'AL V2 fan speed by curve or preset';
  @override
  String get explore => 'Explore';
  @override
  String get exploreSubtitle => 'Effect library';
  @override
  String get settings => 'Settings';
  @override
  String get settingsSubtitle => 'Startup, preferences, and diagnostics';
  @override
  String get settingsTooltip => 'Settings';
  @override
  String get devicesHeader => 'DEVICES';
  @override
  String get detecting => 'Detecting…';
  @override
  String get hideWindow => 'Hide window';
  @override
  String get showWindow => 'Show window';
  @override
  String get turnOffAllArgb => 'Turn off all ARGB';
  @override
  String get quit => 'Quit';
  @override
  String get about => 'About';
  @override
  String get legalese =>
      'MIT License · © 2026 Lucas Silva (lcsssilva)\n'
      'Independent project, not affiliated with the hardware manufacturers.';
  @override
  String get licenses => 'Licenses…';
  @override
  String get configuration => 'Configuration';
  @override
  String get exportOrImport => 'Export or import';
  @override
  String get exportOrImportDescription =>
      'Preferences, lighting, and fans in one JSON file. Importing applies '
      'immediately and keeps a copy of the current configuration.';
  @override
  String get export => 'Export…';
  @override
  String get import => 'Import…';
  @override
  String get exportDialogTitle => 'Export configuration';
  @override
  String get importDialogTitle => 'Import configuration';
  @override
  String exportedTo(String path) => 'Configuration exported to $path.';
  @override
  String importedBackupAt(String path) =>
      'Configuration imported and applied. The previous one was saved as $path.';
  @override
  String failed(String error) => 'Failed. Technical details: $error';
  @override
  String get invalidJson => 'The file is not valid JSON.';
  @override
  String get notAppConfig => 'The file is not an app configuration.';
  @override
  String get newerVersion => 'The file came from a newer version of the app.';
  @override
  String get noKnownSections =>
      'The file has no preferences, lighting, or fans.';
  @override
  String fileTooLarge(int megabytes) =>
      'The file is larger than $megabytes MB and is not a configuration.';
  @override
  String get startupFailedTitle => 'Lumivent could not start';
  @override
  String get startupFailedHint =>
      'The error was written to the terminal. Check the configuration or open '
      'its folder to fix the problem.';
  @override
  String configurationAt(String path) => 'Configuration: $path';
  @override
  String get openConfigurationFolder => 'Open configuration folder';
  @override
  String openFolderFailed(String error) =>
      'Could not open the folder. Technical details: $error';
  @override
  String get underConstruction => 'Under construction';
  @override
  String phase(int phase) => 'Phase $phase';
}

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
