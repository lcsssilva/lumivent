import 'package:flutter_riverpod/misc.dart' show Override;

import '../../core/persistence/config_store.dart';
import '../devices/devices.dart' show Alv2HubProxy;
import 'application/installed_effects_controller.dart';
import 'application/lighting_controller.dart';
import 'application/lighting_engine_module.dart';
import 'domain/lighting_config.dart';
import 'infrastructure/device_light_outputs.dart';
import 'infrastructure/file_effect_importer.dart';
import 'infrastructure/file_effect_library.dart';
import 'infrastructure/json_lighting_config_repository.dart';
import 'infrastructure/logind_power_watcher.dart';
import 'infrastructure/html_effects/runtime.dart';

/// Module composition: connects ports to implementations.
abstract final class LightingModule {
  static LightingConfigRepository repository(ConfigStore store) =>
      JsonLightingConfigRepository(store);

  static List<Override> overrides(ConfigStore store) {
    // One library instance shared by the list and the importer, so the cache
    // invalidation after an import reaches both.
    final library = FileEffectLibrary(defaultEffectsDir());
    return [
      lightingRepositoryProvider.overrideWithValue(repository(store)),
      effectLibraryProvider.overrideWithValue(library),
      effectImporterProvider.overrideWithValue(FileEffectImporter(library)),
      effectRuntimeFactoryProvider.overrideWithValue(
        const HtmlEffectRuntimeFactory(),
      ),
    ];
  }

  /// Engine part. Called inside the isolate. [hub] is shared with monitoring
  /// and fans (monitoring releases it); ITE, SMBus, and the logind watcher
  /// are opened here.
  static LightingEngineModule engine({
    required Alv2HubProxy hub,
    required LightingConfig initial,
    required int fps,
  }) => LightingEngineModule(
    openOutputs: () => DeviceLightOutputs.open(hub),
    openWatcher: LogindPowerWatcher.new,
    initial: initial,
    fps: fps,
  );
}
