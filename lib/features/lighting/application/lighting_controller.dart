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
/// back to "Grupo N".
final fanGroupNamesProvider = Provider<List<String>>(
  (ref) => const ['Grupo 0', 'Grupo 1', 'Grupo 2', 'Grupo 3'],
);

/// Lighting configuration: every change goes to the engine immediately; the
/// save is debounced, because the canvas editor and the sliders change the
/// config on every pointer move.
class LightingController extends Notifier<LightingConfig> {
  static const saveDelay = Duration(milliseconds: 500);

  Timer? _saveTimer;

  @override
  LightingConfig build() {
    ref.onDispose(() {
      if (_saveTimer?.isActive ?? false) _save();
      _saveTimer?.cancel();
    });
    return ref.read(lightingRepositoryProvider).load();
  }

  /// Turns all ARGB off/on: saves right away and notifies the engine.
  void setArgbOff(bool off) {
    if (state.argbOff == off) return;
    state = state.copyWith(argbOff: off);
    ref.read(engineProvider).send(SetArgbOff(off));
    _saveTimer?.cancel();
    _save();
  }

  /// Applies [change] to the current config (no-op if nothing changed).
  void update(LightingConfig Function(LightingConfig current) change) {
    final next = change(state);
    if (next == state) return;
    state = next;
    ref.read(engineProvider).send(SetLightingConfig(next));
    _saveTimer?.cancel();
    _saveTimer = Timer(saveDelay, _save);
  }

  /// Reloads the saved config (after an import) and hands it to the engine.
  /// A pending debounced save is dropped: it would overwrite the import.
  void reload() {
    _saveTimer?.cancel();
    state = ref.read(lightingRepositoryProvider).load();
    ref.read(engineProvider).send(SetLightingConfig(state));
  }

  /// Pings a fan group (1–3) so the user can find it.
  void identify(int hubGroup) =>
      ref.read(engineProvider).send(IdentifyFanGroup(hubGroup));

  void _save() => ref
      .read(lightingRepositoryProvider)
      .save(state)
      .catchError((Object e) => debugPrint('failed to save lighting: $e'));
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
