// Installed HTML/Canvas effects (plan §5.2–5.4): the library list, imports and
// removal. The UI reads/writes through this controller; the library itself is
// a domain port implemented in infrastructure.

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/effect_library.dart';
import '../domain/import_report.dart';
import '../domain/effect_importer.dart';
import '../domain/effect_runtime_factory.dart';
import '../domain/installed_effect.dart';

final effectLibraryProvider = Provider<EffectLibrary>(
  (ref) => throw UnimplementedError('effectLibraryProvider'),
);

final effectImporterProvider = Provider<EffectImporter>(
  (ref) => throw UnimplementedError('effectImporterProvider'),
);

final effectRuntimeFactoryProvider = Provider<EffectRuntimeFactory>(
  (ref) => throw UnimplementedError('effectRuntimeFactoryProvider'),
);

class InstalledEffectsNotifier extends AsyncNotifier<List<InstalledEffect>> {
  @override
  Future<List<InstalledEffect>> build() =>
      ref.read(effectLibraryProvider).list();

  /// Re-reads the folder after an import or removal.
  Future<List<InstalledEffect>> reload() async {
    ref.invalidateSelf();
    return future;
  }

  Future<ImportReport> importPaths(List<String> paths) async {
    final report = await ref.read(effectImporterProvider).importPaths(paths);
    await reload();
    return report;
  }

  Future<ImportReport> importWindowsCache(String folder) async {
    final report = await ref
        .read(effectImporterProvider)
        .importWindowsCache(folder);
    await reload();
    return report;
  }

  /// Removes effect [id]. The caller must switch the global effect first when
  /// [id] is the one being shown.
  Future<void> remove(String id) async {
    await ref.read(effectLibraryProvider).remove(id);
    await reload();
  }

  Future<Uint8List?> thumbnail(String id) =>
      ref.read(effectLibraryProvider).thumbnail(id);
}

final installedEffectsProvider =
    AsyncNotifierProvider<InstalledEffectsNotifier, List<InstalledEffect>>(
      InstalledEffectsNotifier.new,
    );
