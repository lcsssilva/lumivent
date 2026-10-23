import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/html_effect_runner.dart';
import '../../application/installed_effects_notifier.dart';
import '../../application/lighting_notifier.dart';
import '../../application/lighting_status_notifier.dart';
import '../../domain/canvas_rect.dart';
import '../../domain/light_device.dart';
import '../../domain/lighting_config.dart';
import 'lighting_ui_state.dart';

/// Presentation state of the lighting view: the selected device and the
/// global settings, effect choice, and device placement on the canvas.
/// Changes go to [LightingNotifier], which hands them to the engine and
/// saves them.
class LightingViewModel extends Notifier<LightingUiState> {
  /// Kept across rebuilds of [build] (every config change rebuilds).
  LightDeviceId? _selectedDevice;

  @override
  LightingUiState build() => LightingUiState(
    config: ref.watch(lightingProvider),
    installedLibrary: ref.watch(installedEffectsProvider),
    runnerStatus: ref.watch(htmlEffectRunnerProvider),
    frames: ref.watch(htmlEffectFramesProvider),
    status: ref.watch(lightingStatusProvider),
    fanGroupNames: ref.watch(fanGroupNamesProvider),
    selectedDevice: _selectedDevice,
  );

  LightingNotifier get _lighting => ref.read(lightingProvider.notifier);

  /// Shows the controls of [device]; `null` shows the global effect.
  void selectDevice(LightDeviceId? device) {
    _selectedDevice = device;
    state = state.withSelectedDevice(device);
  }

  void turnArgbOn() => _lighting.setArgbOff(false);

  void setBrightness(double brightness) =>
      _lighting.update((c) => c.copyWith(brightness: brightness));

  void setOffOnSleep(bool enabled) =>
      _lighting.update((c) => c.copyWith(offOnSleep: enabled));

  void setAutoHardware(bool enabled) =>
      _lighting.update((c) => c.copyWith(autoHardware: enabled));

  /// Applies a native or installed effect by its `LightingConfig.effectId`.
  void selectEffect(String effectId) =>
      _lighting.update((c) => c.copyWith(effectId: effectId));

  /// Applies an edit made in one of the device panels.
  void edit(LightingConfigEdit change) => _lighting.update(change);

  /// Pings hub group [group] (1–3) so the user can find it.
  void identify(int group) => _lighting.identify(group);

  /// Moves [device] to [placement] on the canvas.
  void placeDevice(LightDeviceId device, CanvasRect placement) =>
      _lighting.update(
        (c) => c.withDevice(
          device,
          c.device(device).copyWith(placement: placement),
        ),
      );
}

final lightingViewModelProvider =
    NotifierProvider.autoDispose<LightingViewModel, LightingUiState>(
      LightingViewModel.new,
    );
