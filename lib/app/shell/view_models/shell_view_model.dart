import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/devices/devices.dart';
import '../../../features/lighting/lighting.dart';
import '../../../features/monitoring/monitoring.dart';
import '../../../features/preferences/preferences.dart';
import '../../navigation/app_route.dart';
import '../../navigation/route_notifier.dart';
import 'shell_ui_state.dart';

/// Presentation state of the shell frame (sidebar and top bar): navigation
/// and the global ARGB switch.
class ShellViewModel extends Notifier<ShellUiState> {
  @override
  ShellUiState build() => ShellUiState(
    route: ref.watch(routeProvider),
    temperatureUnit: ref.watch(
      preferencesProvider.select((p) => p.temperatureUnit),
    ),
    argbOff: ref.watch(lightingProvider.select((c) => c.argbOff)),
    latestSensors: ref.watch(monitoringProvider.select((m) => m.latest)),
    devices: ref.watch(devicesProvider),
  );

  void go(AppRoute route) => ref.read(routeProvider.notifier).go(route);

  /// Turns all ARGB off (`true`) or back on (`false`).
  void setArgbOff(bool off) =>
      ref.read(lightingProvider.notifier).setArgbOff(off);
}

final shellViewModelProvider =
    NotifierProvider.autoDispose<ShellViewModel, ShellUiState>(
      ShellViewModel.new,
    );
