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

/// What an import did, for the message shown to the user.
class ImportReport {
  ImportReport({
    this.imported = 0,
    this.replaced = 0,
    this.skipped = 0,
    this.paidSkipped = 0,
    List<String>? errors,
    this.catalogFound = false,
  }) : errors = errors ?? [];

  int imported;
  int replaced;
  int skipped;

  /// Windows cache import: paid effects left out (subscription or purchase).
  int paidSkipped;
  final List<String> errors;

  /// Windows cache import: `catalog_en.json` was found (names and tags).
  bool catalogFound;

  int get total => imported + replaced;

  bool get isEmpty => total == 0 && paidSkipped == 0 && errors.isEmpty;

  void add(ImportReport other) {
    imported += other.imported;
    replaced += other.replaced;
    skipped += other.skipped;
    paidSkipped += other.paidSkipped;
    errors.addAll(other.errors);
    catalogFound = catalogFound || other.catalogFound;
  }

  String get summary {
    final parts = <String>[];
    if (imported > 0) {
      parts.add('$imported importado${imported == 1 ? '' : 's'}');
    }
    if (replaced > 0) {
      parts.add('$replaced substituído${replaced == 1 ? '' : 's'}');
    }
    if (skipped > 0) parts.add('$skipped ignorado${skipped == 1 ? '' : 's'}');
    if (paidSkipped > 0) {
      final s = paidSkipped == 1 ? '' : 's';
      parts.add('$paidSkipped pago$s não importado$s');
    }
    if (errors.isNotEmpty) {
      parts.add('${errors.length} erro${errors.length == 1 ? '' : 's'}');
    }
    return parts.isEmpty ? 'Nada para importar.' : parts.join(', ');
  }

  @override
  String toString() => 'ImportReport($summary)';
}

/// Imports effect files from the paths the user picked.
abstract interface class EffectImporter {
  /// Accepts `.html` files, folders (with `effect.html` or one folder per
  /// effect) and `.zip` files. Invalid paths become entries in
  /// [ImportReport.errors].
  Future<ImportReport> importPaths(List<String> paths);

  /// Reads an effects folder of a Windows installation: `<cache>` or its
  /// parent. Never mounts anything.
  Future<ImportReport> importWindowsCache(String folder);
}
