import '../../../features/devices/devices.dart';
import '../../../features/monitoring/monitoring.dart';
import '../../../features/preferences/preferences.dart';
import '../../navigation/app_route.dart';

/// What the shell frame shows around the current page: the route, the
/// top-bar readings and ARGB switch, and the sidebar device summary.
class ShellUiState {
  const ShellUiState({
    required this.route,
    required this.temperatureUnit,
    required this.argbOff,
    this.latestSensors,
    this.devices,
  });

  final AppRoute route;
  final TemperatureUnit temperatureUnit;

  /// Whether all ARGB is off.
  final bool argbOff;

  /// Latest sensor reading, `null` before the first one.
  final SensorSample? latestSensors;

  /// Last device detection, `null` while the first scan runs.
  final DeviceSnapshot? devices;
}
