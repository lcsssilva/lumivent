part of 'html_effect_runner_test.dart';

class _RunnerLightingRepository implements LightingConfigRepository {
  LightingConfig config = LightingConfig(effectId: 'html:test');

  @override
  LightingConfig load() => config;

  @override
  Future<void> save(LightingConfig c) async => config = c;
}
