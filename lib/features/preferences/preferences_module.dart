import 'package:flutter_riverpod/misc.dart' show Override;

import '../../core/persistence/config_store.dart';
import 'application/preferences_notifier.dart';
import 'domain/preferences_repository.dart' show PreferencesRepository;
import 'infrastructure/json_preferences_repository.dart';

/// Module composition: connects ports to implementations.
abstract final class PreferencesModule {
  static PreferencesRepository repository(ConfigStore store) =>
      JsonPreferencesRepository(store);

  static List<Override> overrides(ConfigStore store) => [
    preferencesRepositoryProvider.overrideWithValue(repository(store)),
  ];
}
