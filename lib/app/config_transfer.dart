// Export/import of the whole configuration (plan §4.2, item 5).
//
// The file is the `config.json` itself: every module section plus `version`.
// Import keeps only the module sections it knows, writes them in one go after
// a backup of the current file, and the caller reloads the modules so the
// change applies without restarting the app.
import 'dart:convert';

import '../core/i18n/app_strings.dart';
import '../core/persistence/config_store.dart';

/// Module sections an import may replace.
const transferableSections = ['preferences', 'lighting', 'fans'];

/// Suffix of the copy of `config.json` taken before an import.
const importBackupSuffix = 'antes-import';

/// Default name of an exported file.
const exportFileName = 'lumivent-config.json';

/// The configuration as exported (pretty JSON).
String exportConfig(ConfigStore store) =>
    const JsonEncoder.withIndent('  ').convert(store.snapshot());

/// Module sections of an exported file.
///
/// Throws [FormatException] (message in [strings]) when [text] is not a JSON
/// object, comes from a newer schema, or carries no known section.
JsonMap importableSections(String text, {AppStrings strings = AppStrings.en}) {
  final Object? json;
  try {
    json = jsonDecode(text);
  } on FormatException {
    throw FormatException(strings.shell.invalidJson);
  }
  if (json is! JsonMap) {
    throw FormatException(strings.shell.notAppConfig);
  }
  final version = json['version'];
  if (version is num && version > ConfigStore.schemaVersion) {
    throw FormatException(strings.shell.newerVersion);
  }
  final sections = <String, Object?>{
    for (final name in transferableSections)
      if (json[name] is JsonMap) name: json[name],
  };
  if (sections.isEmpty) {
    throw FormatException(strings.shell.noKnownSections);
  }
  return sections;
}

/// Imports [text] into [store] (backup first). Returns the imported section
/// names; the caller reloads those modules.
Future<List<String>> importConfig(
  ConfigStore store,
  String text, {
  AppStrings strings = AppStrings.en,
}) async {
  final sections = importableSections(text, strings: strings);
  await store.replaceSections(sections, backupSuffix: importBackupSuffix);
  return sections.keys.toList();
}
