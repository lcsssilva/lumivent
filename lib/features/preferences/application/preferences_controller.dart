import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/preferences.dart';

final preferencesRepositoryProvider = Provider<PreferencesRepository>(
  (ref) => throw UnimplementedError('preferencesRepositoryProvider'),
);

class PreferencesController extends Notifier<Preferences> {
  @override
  Preferences build() => ref.read(preferencesRepositoryProvider).load();

  /// Reloads the saved preferences (after an import). Listeners such as the
  /// FPS one in `bootstrap.dart` pick up the change.
  void reload() => state = ref.read(preferencesRepositoryProvider).load();

  void change(Preferences Function(Preferences) f) {
    final next = f(state);
    if (next == state) return;
    state = next;
    ref
        .read(preferencesRepositoryProvider)
        .save(next)
        .catchError((Object e) => debugPrint('failed to save preferences: $e'));
  }
}

final preferencesProvider =
    NotifierProvider<PreferencesController, Preferences>(
      PreferencesController.new,
    );
