/// Explore page: effect library, filters, import, and import reports.
abstract class ExploreStrings {
  const ExploreStrings();

  String get subtitle;

  // Import buttons and dialogs.
  String get importEffect;
  String get folder;
  String get importFromWindows;
  String get importEffectsDialogTitle;
  String get importFolderDialogTitle;
  String get importWindowsDialogTitle;

  // Search and filters.
  String get searchHint;
  String get filterAll;
  String get filterCompatible;
  String get filterPartial;
  String get filterUnsupported;
  String get allCategories;
  String get allPublishers;

  // Library states.
  String get libraryReadFailed;
  String get noMatch;
  String get noEffectsTitle;
  String get noEffectsBody;

  // Cards.
  String get compatible;
  String get partial;
  String get unsupported;
  String get appliedBadge;
  String get apply;
  String get applied;
  String get removeFromLibrary;
  String requires(String issues);
  String get originFile;
  String get originFolder;
  String get originZip;
  String get originWindowsCache;

  // Snacks and dialogs.
  String importDone(String summary);
  String importDoneWithError(String summary, String error);
  String importFailed(String error);
  String effectApplied(String name);
  String removeTitle(String name);
  String get removeAppliedBody;
  String get removeBody;
  String effectRemoved(String name);
  String removeFailed(String error);

  /// Summary of an import: imported/replaced/skipped/paid/errors.
  String importSummary({
    required int imported,
    required int replaced,
    required int skipped,
    required int paidSkipped,
    required int errors,
  });

  // Import errors: [path] and [error] are data.
  String importNotHtmlOrZip(String path);
  String importNotFound(String path);
  String importFolderNotFound(String path);
  String get importChooseWindowsCache;
  String get importCatalogMissing;
  String importNoEffectHtml(String path);
  String importInvalidZip(String path, String error);
  String get importNoHtmlInZip;
  String importTooLarge(String path);
  String importUnsupportedZipEntry(String path);
  String importUnknown(String path, String error);
}
