import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/effects/effect_frame_feed.dart';
import '../../application/effects/html_effect_status.dart';
import '../../application/status/light_output_status.dart';
import '../../application/messages/lighting_status.dart';
import '../../domain/hardware_mode/fan_hardware_mode.dart';
import '../../domain/hardware_mode/hardware_equivalent.dart';
import '../../domain/effects/installed_effect.dart';
import '../../domain/light_device.dart';
import '../../domain/config/lighting_config.dart';

/// Everything the lighting view and its panels render: the configuration,
/// the installed effects, the live device and effect status, and the
/// selected device.
class LightingUiState {
  const LightingUiState({
    required this.config,
    required this.installedLibrary,
    required this.runnerStatus,
    required this.frames,
    this.status,
    this.fanGroupNames = const [],
    this.fanHardwareModes = const [],
    this.selectedDevice,
  });

  final LightingConfig config;

  /// The installed HTML effects as the library loads them.
  final AsyncValue<List<InstalledEffect>> installedLibrary;

  /// Status of the HTML effect being rendered.
  final HtmlEffectStatus runnerStatus;

  /// Frames of the HTML effect, drawn on the canvas preview.
  final EffectFrameFeed frames;

  /// Last device status from the engine (`null` until the first one).
  final LightingStatus? status;

  /// Names of the hub groups 0–3, empty when the user named none.
  final List<String> fanGroupNames;

  /// Firmware modes the AL V2 fan hub offers.
  final List<FanHardwareMode> fanHardwareModes;

  /// Device whose controls are shown; `null` shows the global effect.
  final LightDeviceId? selectedDevice;

  LightingUiState withSelectedDevice(LightDeviceId? device) => LightingUiState(
    config: config,
    installedLibrary: installedLibrary,
    runnerStatus: runnerStatus,
    frames: frames,
    status: status,
    fanGroupNames: fanGroupNames,
    fanHardwareModes: fanHardwareModes,
    selectedDevice: device,
  );

  /// Installed HTML effects, empty while the library loads or after a
  /// failure (the explore view reports library errors).
  List<InstalledEffect> get installedEffects =>
      installedLibrary.value ?? const [];

  /// Output status of [device], `null` before the engine reports it.
  LightOutputStatus? deviceStatus(LightDeviceId device) =>
      status?.devices[device];

  /// Canvas devices the engine hands to the firmware for the current effect.
  Set<LightDeviceId> get autoHardware => autoHardwareDevices(config);
}
