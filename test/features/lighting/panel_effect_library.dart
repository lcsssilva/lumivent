part of 'html_effect_panel_test.dart';

class _PanelEffectLibrary implements EffectLibrary {
  _PanelEffectLibrary(this.effect);
  final InstalledEffect effect;

  @override
  Future<List<InstalledEffect>> list() async => [effect];

  @override
  Future<InstalledEffect?> find(String id) async => effect;

  @override
  Future<String> readHtml(String id) async => '<html></html>';

  @override
  Future<void> remove(String id) async {}

  @override
  Future<void> saveThumbnail(String id, Uint8List png) async {}

  @override
  Future<Uint8List?> thumbnail(String id) async => null;
}
