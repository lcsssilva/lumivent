import '../../domain/installed_effect.dart';
import '../../domain/light_device.dart';
import '../../domain/lighting_config.dart';

/// Configuration, installed effects, and selected device of the lighting
/// view.
class LightingUiState {
  const LightingUiState({
    required this.config,
    required this.installedEffects,
    this.selectedDevice,
  });

  final LightingConfig config;

  /// Installed HTML effects, empty while the library loads or after a
  /// failure (the explore view reports library errors).
  final List<InstalledEffect> installedEffects;

  /// Device whose controls are shown; `null` shows the global effect.
  final LightDeviceId? selectedDevice;

  LightingUiState withSelectedDevice(LightDeviceId? device) => LightingUiState(
    config: config,
    installedEffects: installedEffects,
    selectedDevice: device,
  );
}
