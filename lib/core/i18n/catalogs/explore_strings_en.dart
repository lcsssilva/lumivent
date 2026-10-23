import 'explore_strings.dart';

class ExploreStringsEn extends ExploreStrings {
  const ExploreStringsEn();

  @override
  @override
  String get subtitle => 'Local library of HTML/Canvas effects';
  @override
  String get importEffect => 'Import effect…';
  @override
  String get folder => 'Folder…';
  @override
  String get importFromWindows => 'Import from Windows…';
  @override
  String get importEffectsDialogTitle => 'Import effects (.html or .zip)';
  @override
  String get importFolderDialogTitle => 'Import folder with effects';
  @override
  String get importWindowsDialogTitle =>
      'Windows effects folder (or the cache folder)';
  @override
  String get searchHint => 'Search by name, author, or tag';
  @override
  String get filterAll => 'All';
  @override
  String get filterCompatible => 'Compatible';
  @override
  String get filterPartial => 'Partial';
  @override
  String get filterUnsupported => 'Unsupported';
  @override
  String get allCategories => 'All categories';
  @override
  String get allPublishers => 'All authors';
  @override
  String get libraryReadFailed => 'Could not read the library';
  @override
  String get noMatch => 'No effect matches the filters.';
  @override
  String get noEffectsTitle => 'No effects installed';
  @override
  String get noEffectsBody =>
      'Import an .html file, a folder with effect.html, a ZIP, or the Windows '
      'effects cache folder (paid effects are not imported). Effects are kept '
      'in ~/.local/share/lumivent/effects.';
  @override
  String get appliedBadge => 'Applied';
  @override
  String get compatible => 'Compatible';
  @override
  String get partial => 'Partial';
  @override
  String get unsupported => 'Unsupported';
  @override
  String get apply => 'Apply';
  @override
  String get applied => 'Applied';
  @override
  String get removeFromLibrary => 'Remove from library';
  @override
  String requires(String issues) => 'Requires $issues';
  @override
  String get originFile => 'HTML file';
  @override
  String get originFolder => 'Folder';
  @override
  String get originZip => 'ZIP';
  @override
  String get originWindowsCache => 'Windows';
  @override
  String importDone(String summary) => 'Import finished: $summary';
  @override
  String importDoneWithError(String summary, String error) =>
      '$summary. $error';
  @override
  String importFailed(String error) =>
      'Import failed. Technical details: $error';
  @override
  String effectApplied(String name) =>
      '“$name” applied. Adjust the controls in Lighting.';
  @override
  String removeTitle(String name) => 'Remove “$name”?';
  @override
  String get removeAppliedBody =>
      'It is applied right now and will be replaced by the default effect. '
      'The file will be deleted from the library.';
  @override
  String get removeBody => 'The file will be deleted from the library.';
  @override
  String effectRemoved(String name) => '“$name” removed.';
  @override
  String removeFailed(String error) =>
      'Could not remove the effect. Technical details: $error';
  @override
  String importSummary({
    required int imported,
    required int replaced,
    required int skipped,
    required int paidSkipped,
    required int errors,
  }) {
    final parts = <String>[
      if (imported > 0) '$imported imported',
      if (replaced > 0) '$replaced replaced',
      if (skipped > 0) '$skipped skipped',
      if (paidSkipped > 0) '$paidSkipped paid not imported',
      if (errors > 0) '$errors ${errors == 1 ? 'error' : 'errors'}',
    ];
    return parts.isEmpty ? 'Nothing to import.' : parts.join(', ');
  }

  @override
  String importNotHtmlOrZip(String path) => '$path: not HTML or ZIP';
  @override
  String importNotFound(String path) => '$path: not found';
  @override
  String importFolderNotFound(String path) => '$path: folder not found';
  @override
  String get importChooseWindowsCache =>
      'Choose the Windows effects cache folder.';
  @override
  String get importCatalogMissing =>
      'catalog_en.json not found in the cache folder: without it there is '
      'no way to tell which effects are paid.';
  @override
  String importNoEffectHtml(String path) => 'No effect.html found in $path.';
  @override
  String importInvalidZip(String path, String error) =>
      '$path: invalid ZIP. Technical details: $error';
  @override
  String get importNoHtmlInZip => 'The ZIP has no HTML files.';
  @override
  String importTooLarge(String path) => '$path: exceeds the import size limit.';
  @override
  String importUnsupportedZipEntry(String path) =>
      '$path: skipped, it is a link or another special file.';
  @override
  String importUnknown(String path, String error) =>
      '$path. Technical details: $error';
}
