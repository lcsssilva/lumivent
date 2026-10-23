part of 'html_effect_panel_test.dart';

class _PanelLightingRepository implements LightingConfigRepository {
  LightingConfig config = LightingConfig(effectId: 'html:test');

  @override
  LightingConfig load() => config;

  @override
  Future<void> save(LightingConfig c) async => config = c;
}
