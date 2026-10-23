import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/engine/engine_host.dart';
import '../domain/lighting_config.dart';
import 'lighting_messages.dart';

final lightingRepositoryProvider = Provider<LightingConfigRepository>(
  (ref) => throw UnimplementedError('lightingRepositoryProvider'),
);

/// Names of the AL V2 hub groups (index = group 0–3) on the lighting screen.
/// The app wires it to the names set on the fans page; an empty name falls
/// back to the catalog's default group name.
final fanGroupNamesProvider = Provider<List<String>>((ref) => const []);

/// Lighting configuration: every change goes to the engine immediately; the
/// save is debounced, because the canvas editor and the sliders change the
/// config on every pointer move.
class LightingController extends Notifier<LightingConfig> {
  static const saveDelay = Duration(milliseconds: 500);

  Timer? _saveTimer;

  /// Config waiting for the debounce. Kept here because the dispose callback
  /// cannot read the notifier state or other providers.
  LightingConfig? _unsaved;
  late LightingConfigRepository _repository;

  @override
  LightingConfig build() {
    _repository = ref.read(lightingRepositoryProvider);
    ref.onDispose(savePending);
    return _repository.load();
  }

  /// Turns all ARGB off/on: saves right away and notifies the engine.
  void setArgbOff(bool off) {
    if (state.argbOff == off) return;
    state = state.copyWith(argbOff: off);
    ref.read(engineProvider).send(SetArgbOff(off));
    _cancelPendingSave();
    _save(state);
  }

  /// Applies [change] to the current config (no-op if nothing changed).
  void update(LightingConfig Function(LightingConfig current) change) {
    final next = change(state);
    if (next == state) return;
    state = next;
    ref.read(engineProvider).send(SetLightingConfig(next));
    _saveTimer?.cancel();
    _unsaved = next;
    _saveTimer = Timer(saveDelay, savePending);
  }

  /// Reloads the saved config (after an import) and hands it to the engine.
  /// A pending debounced save is dropped: it would overwrite the import.
  void reload() {
    _cancelPendingSave();
    state = ref.read(lightingRepositoryProvider).load();
    ref.read(engineProvider).send(SetLightingConfig(state));
  }

  /// Pings a fan group (1–3) so the user can find it.
  void identify(int hubGroup) =>
      ref.read(engineProvider).send(IdentifyFanGroup(hubGroup));

  /// Saves a change still waiting for the debounce right away (quit,
  /// dispose). Does nothing when every change is already saved.
  void savePending() {
    final pending = _unsaved;
    _cancelPendingSave();
    if (pending != null) _save(pending);
  }

  void _cancelPendingSave() {
    _saveTimer?.cancel();
    _unsaved = null;
  }

  void _save(LightingConfig config) => _repository
      .save(config)
      // The store names the section and notifies the user; the cause and
      // stack trace are logged for troubleshooting.
      .catchError((Object e, StackTrace s) => debugPrint('$e\n$s'));
}

final lightingProvider = NotifierProvider<LightingController, LightingConfig>(
  LightingController.new,
);

/// Last per-device output status from the engine (`null` until the first one).
class LightingStatusController extends Notifier<LightingStatus?> {
  @override
  LightingStatus? build() {
    final engine = ref.watch(engineProvider);
    final sub = engine.events.listen((e) {
      if (e is LightingStatus) state = e;
    });
    ref.onDispose(sub.cancel);
    return engine.lastEvent<LightingStatus>();
  }
}

final lightingStatusProvider =
    NotifierProvider<LightingStatusController, LightingStatus?>(
      LightingStatusController.new,
    );
