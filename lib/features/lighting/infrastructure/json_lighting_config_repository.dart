import '../../../core/persistence/config_store.dart';
import '../domain/config/lighting_config.dart';
import '../domain/config/lighting_config_repository.dart';
import 'lighting_codec.dart';

/// Stores configuration in the `lighting` section of config.json. Also reads the
/// old config `{"argbOff": true}`.
class JsonLightingConfigRepository implements LightingConfigRepository {
  JsonLightingConfigRepository(this._store);

  static const section = 'lighting';
  final ConfigStore _store;

  @override
  LightingConfig load() => decodeLightingConfig(_store.section(section));

  @override
  Future<void> save(LightingConfig config) =>
      _store.saveSection(section, encodeLightingConfig(config));
}
