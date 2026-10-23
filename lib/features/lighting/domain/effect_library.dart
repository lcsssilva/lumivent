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

  /// A file or ZIP entry over the import size limit.
  tooLarge,

  /// A ZIP entry that is a symlink or another non-regular file.
  unsupportedZipEntry,
  unknown,
}
