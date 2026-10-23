import 'lighting_config.dart';

/// Persistence port for lighting configuration.
abstract interface class LightingConfigRepository {
  LightingConfig load();
  Future<void> save(LightingConfig config);
}
