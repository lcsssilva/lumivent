part of 'html_effect_runner_test.dart';

class _RunnerPreferencesRepository implements PreferencesRepository {
  @override
  Preferences load() => const Preferences();

  @override
  Future<void> save(Preferences preferences) async {}
}
