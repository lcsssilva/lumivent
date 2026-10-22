import '../../../core/persistence/config_store.dart';
import '../domain/preferences.dart';
import 'preferences_codec.dart';

/// Stores preferences in the `preferences` section of config.json.
class JsonPreferencesRepository implements PreferencesRepository {
  JsonPreferencesRepository(this._store);

  static const section = 'preferences';
  final ConfigStore _store;

  @override
  Preferences load() => decodePreferences(_store.section(section));

  @override
  Future<void> save(Preferences preferences) =>
      _store.saveSection(section, encodePreferences(preferences));
}
