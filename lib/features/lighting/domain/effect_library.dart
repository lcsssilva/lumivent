// Lighting module domain (pure Dart): ports of the installed-effect library
// and of the importer (plan §5.2 and §5.3).

import 'dart:typed_data';

import 'installed_effect.dart';

/// Reads and removes effects under `~/.local/share/lumivent/effects`.
abstract interface class EffectLibrary {
  /// Effects found on disk (newest import first). Unreadable folders are
  /// skipped.
  Future<List<InstalledEffect>> list();

  /// `effect.html` of [id]. Throws when the effect does not exist.
  Future<String> readHtml(String id);

  Future<InstalledEffect?> find(String id);

  Future<void> remove(String id);

  /// Stores the preview image (`thumbnail.png`) of [id].
  Future<void> saveThumbnail(String id, Uint8List png);

  Future<Uint8List?> thumbnail(String id);
}

/// Why a path or entry could not be imported. Stable ids translated by the
/// presentation layer.
enum ImportIssueKind {
  notHtmlOrZip,
  notFound,
  folderNotFound,
  chooseWindowsCache,
  catalogMissing,
  noEffectHtml,
  invalidZip,
  noHtmlInZip,
  unknown,
}

/// One import failure: [path] is the original user path or ZIP entry, [detail]
/// the technical error (never shown untranslated).
class ImportIssue {
  const ImportIssue(this.kind, {this.path, this.detail});

  final ImportIssueKind kind;
  final String? path;
  final String? detail;

  @override
  String toString() =>
      'ImportIssue(${kind.name}${path == null ? '' : ': $path'})';
}

/// What an import did, for the message shown to the user.
class ImportReport {
  ImportReport({
    this.imported = 0,
    this.replaced = 0,
    this.skipped = 0,
    this.paidSkipped = 0,
    List<ImportIssue>? issues,
    this.catalogFound = false,
  }) : issues = issues ?? [];

  int imported;
  int replaced;
  int skipped;

  /// Windows cache import: paid effects left out (subscription or purchase).
  int paidSkipped;
  final List<ImportIssue> issues;

  /// Windows cache import: `catalog_en.json` was found (names and tags).
  bool catalogFound;

  int get total => imported + replaced;

  bool get isEmpty => total == 0 && paidSkipped == 0 && issues.isEmpty;

  void add(ImportReport other) {
    imported += other.imported;
    replaced += other.replaced;
    skipped += other.skipped;
    paidSkipped += other.paidSkipped;
    issues.addAll(other.issues);
    catalogFound = catalogFound || other.catalogFound;
  }

  @override
  String toString() =>
      'ImportReport(imported: $imported, replaced: $replaced, '
      'skipped: $skipped, paidSkipped: $paidSkipped, '
      'issues: ${issues.length})';
}

/// Imports effect files from the paths the user picked.
abstract interface class EffectImporter {
  /// Accepts `.html` files, folders (with `effect.html` or one folder per
  /// effect) and `.zip` files. Invalid paths become entries in
  /// [ImportReport.issues].
  Future<ImportReport> importPaths(List<String> paths);

  /// Reads an effects folder of a Windows installation: `<cache>` or its
  /// parent. Never mounts anything.
  Future<ImportReport> importWindowsCache(String folder);
}
