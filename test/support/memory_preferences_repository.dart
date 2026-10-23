import 'package:lumivent/features/preferences/domain/preferences.dart';
import 'package:lumivent/features/preferences/domain/preferences_repository.dart';

/// Keeps the preferences in memory.
class MemoryPreferencesRepository implements PreferencesRepository {
  Preferences preferences = const Preferences();

  @override
  Preferences load() => preferences;

  @override
  Future<void> save(Preferences preferences) async =>
      this.preferences = preferences;
}
