import 'package:flutter_riverpod/misc.dart' show Override;

import '../../core/persistence/config_store.dart';
import 'application/preferences_controller.dart';
import 'infrastructure/preferences_store.dart';

/// Module composition: connects ports to implementations.
abstract final class PreferencesModule {
  static List<Override> overrides(ConfigStore store) => [
    preferencesRepositoryProvider.overrideWithValue(
      JsonPreferencesRepository(store),
    ),
  ];
}
