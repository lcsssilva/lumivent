import 'package:lumivent/features/lighting/domain/effect_importer.dart';
import 'package:lumivent/features/lighting/domain/import_report.dart';

class NoEffectImporter implements EffectImporter {
  @override
  Future<ImportReport> importPaths(List<String> paths) async => ImportReport();

  @override
  Future<ImportReport> importWindowsCache(String folder) async =>
      ImportReport();
}
