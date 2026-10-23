import 'preferences.dart';

/// Persistence port for preferences.
abstract interface class PreferencesRepository {
  Preferences load();
  Future<void> save(Preferences preferences);
}
