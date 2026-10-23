part of 'html_effect_panel_test.dart';

class _PanelPreferencesRepository implements PreferencesRepository {
  @override
  Preferences load() => const Preferences();

  @override
  Future<void> save(Preferences preferences) async {}
}
