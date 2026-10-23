import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/engine/isolate_engine.dart';
import '../domain/fan_group_config.dart';
import '../domain/fans_config.dart';
import '../domain/fans_repository.dart';
import 'messages/set_fans_config.dart';

final fansRepositoryProvider = Provider<FansRepository>(
  (ref) => throw UnimplementedError('fansRepositoryProvider'),
);

/// Fan configuration: each change is sent to the engine immediately and saved.
class FansNotifier extends Notifier<FansConfig> {
  @override
  FansConfig build() => ref.read(fansRepositoryProvider).load();

  /// Changes a group's configuration. With [persist] `false`, only the engine
  /// is notified (used while dragging; save at the end with [persist] `true`).
  void updateGroup(FanGroupConfig group, {bool persist = true}) =>
      _set(state.replaced(group), persist: persist);

  /// Copies the curve from [group] to all other groups.
  void applyCurveToAll(int group) => _set(state.curveAppliedToAll(group));

  /// Reloads the saved config (after an import) and hands it to the engine.
  void reload() {
    state = ref.read(fansRepositoryProvider).load();
    ref.read(engineProvider).send(SetFansConfig(state));
  }

  /// Saves the current state (end of a drag performed with `persist: false`).
  void persist() => _save();

  void _set(FansConfig next, {bool persist = true}) {
    state = next;
    ref.read(engineProvider).send(SetFansConfig(next));
    if (persist) _save();
  }

  void _save() => ref
      .read(fansRepositoryProvider)
      .save(state)
      // The store names the section and notifies the user; the cause and
      // stack trace are logged for troubleshooting.
      .catchError((Object e, StackTrace s) => debugPrint('$e\n$s'));
}

final fansProvider = NotifierProvider<FansNotifier, FansConfig>(
  FansNotifier.new,
);
