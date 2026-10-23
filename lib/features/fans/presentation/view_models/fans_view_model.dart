import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../monitoring/monitoring.dart';
import '../../../preferences/preferences.dart';
import '../../application/fans_notifier.dart';
import '../../application/fans_status_notifier.dart';
import '../../domain/fan_curve.dart';
import '../../domain/fan_group.dart';
import '../../domain/fan_group_config.dart';
import '../../domain/fan_response.dart';
import 'fans_ui_state.dart';

/// Presentation state of the fans view: the selected group and the user's
/// edits to it. Changes go to [FansNotifier], which hands them to the engine
/// and saves them.
class FansViewModel extends Notifier<FansUiState> {
  /// Group chosen by the user; kept across rebuilds of [build].
  int? _selectedGroup;

  @override
  FansUiState build() => FansUiState(
    config: ref.watch(fansProvider),
    history: ref.watch(monitoringProvider.select((m) => m.history)),
    status: ref.watch(fansStatusProvider),
    temperatureUnit: ref.watch(
      preferencesProvider.select((p) => p.temperatureUnit),
    ),
    selectedGroup: _selectedGroup,
  );

  FansNotifier get _fans => ref.read(fansProvider.notifier);

  void selectGroup(int group) {
    _selectedGroup = group;
    state = state.withSelectedGroup(group);
  }

  /// Copies the selected group's curve to all other groups.
  void applyCurveToAll() => _fans.applyCurveToAll(state.selectedIndex);

  /// Renames the selected group; a blank name keeps the current one.
  void renameGroup(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    _update((g) => g.copyWith(name: trimmed));
  }

  void setSize(FanSize size) => _update((g) => g.copyWith(size: size));

  void setPreset(FanPreset preset) =>
      _update((g) => g.copyWith(preset: preset));

  /// Applies a curve while it is being dragged, without saving it.
  void previewCurve(FanGroupConfig group) =>
      _fans.updateGroup(group, persist: false);

  /// Saves the curve at the end of a drag.
  void commitCurve() => _fans.persist();

  void setStartStop(bool enabled) =>
      _update((g) => g.copyWith(startStop: enabled));

  void setSource(FanTempSource source) =>
      _update((g) => g.copyWith(source: source));

  void setResponse(FanResponse response) =>
      _update((g) => g.copyWith(response: response));

  void _update(FanGroupConfig Function(FanGroupConfig) change) =>
      _fans.updateGroup(change(state.group));
}

final fansViewModelProvider =
    NotifierProvider.autoDispose<FansViewModel, FansUiState>(FansViewModel.new);
