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
