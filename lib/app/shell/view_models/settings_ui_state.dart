import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/devices/devices.dart';
import '../../../features/preferences/preferences.dart';
import '../../../features/system/system.dart';

/// Everything the settings cards show.
class SettingsUiState {
  const SettingsUiState({
    required this.preferences,
    required this.trayAvailable,
    required this.autostart,
    required this.autostartLocation,
    required this.checks,
    this.devices,
  });

  final Preferences preferences;

  /// Without a system tray, closing the window exits the app.
  final bool trayAvailable;

  /// Autostart state as the service reports it.
  final AsyncValue<AutostartState> autostart;

  /// Path of the systemd unit.
  final String autostartLocation;

  /// Environment checks followed by the checks of the running engine.
  final List<DiagnosticCheck> checks;

  /// Last device detection, `null` while the first scan runs.
  final DeviceSnapshot? devices;
}
