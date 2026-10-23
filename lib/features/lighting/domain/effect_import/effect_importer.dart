import 'import_report.dart';

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
