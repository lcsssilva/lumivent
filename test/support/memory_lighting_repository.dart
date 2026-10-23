import 'package:lumivent/features/lighting/domain/lighting_config.dart';
import 'package:lumivent/features/lighting/domain/lighting_config_repository.dart';

/// Keeps the lighting configuration in memory and counts the saves.
class MemoryLightingRepository implements LightingConfigRepository {
  LightingConfig config = LightingConfig();
  int saves = 0;

  @override
  LightingConfig load() => config;

  @override
  Future<void> save(LightingConfig c) async {
    config = c;
    saves++;
  }
}
