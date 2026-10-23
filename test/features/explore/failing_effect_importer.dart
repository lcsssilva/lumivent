import 'package:lumivent/features/lighting/domain/effect_importer.dart';
import 'package:lumivent/features/lighting/domain/import_report.dart';

/// Every import fails with [error].
class FailingEffectImporter implements EffectImporter {
  FailingEffectImporter(this.error);

  final Object error;

  @override
  Future<ImportReport> importPaths(List<String> paths) async => throw error;

  @override
  Future<ImportReport> importWindowsCache(String folder) async => throw error;
}
