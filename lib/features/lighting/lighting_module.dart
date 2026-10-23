import 'package:flutter_riverpod/misc.dart' show Override;

import '../../core/persistence/config_store.dart';
import '../devices/devices.dart' show Alv2HubProxy;
import 'application/effects/installed_effects_notifier.dart';
import 'application/lighting_notifier.dart';
import 'application/lighting_engine_module.dart';
import 'domain/config/lighting_config.dart';
import 'domain/config/lighting_config_repository.dart';
import 'infrastructure/alv2_fan_hardware_modes.dart';
import 'infrastructure/light_io/device_light_outputs.dart';
import 'infrastructure/effect_import/file_effect_importer.dart';
import 'infrastructure/effect_import/file_effect_library.dart';
import 'infrastructure/json_lighting_config_repository.dart';
import 'infrastructure/power/logind_power_watcher.dart';
import 'infrastructure/html_effects/html_effect_runtime_factory.dart';

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
      fanHardwareModesProvider.overrideWithValue(alv2FanHardwareModes),
      effectLibraryProvider.overrideWithValue(library),
      effectImporterProvider.overrideWithValue(FileEffectImporter(library)),
      effectRuntimeFactoryProvider.overrideWithValue(
        HtmlEffectRuntimeFactory(),
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
