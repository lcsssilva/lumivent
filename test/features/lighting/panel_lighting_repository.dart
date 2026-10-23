import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/lighting/domain/config/lighting_config.dart';
import 'package:lumivent/features/lighting/domain/config/lighting_config_repository.dart';

class PanelLightingRepository implements LightingConfigRepository {
  LightingConfig config = LightingConfig(effectId: 'html:test');

  @override
  LightingConfig load() => config;

  @override
  Future<void> save(LightingConfig c) async => config = c;
}
