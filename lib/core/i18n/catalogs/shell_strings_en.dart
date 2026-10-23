import 'shell_strings.dart';

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
