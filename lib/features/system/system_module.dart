import 'package:flutter_riverpod/misc.dart' show Override;

import 'application/system_controller.dart';
import 'infrastructure/linux_diagnostics.dart';
import 'infrastructure/systemd_autostart.dart';

/// Module composition: connects ports to implementations.
abstract final class SystemModule {
  /// [executable]: binary that autostart will launch.
  static List<Override> overrides({required String executable}) => [
    autostartServiceProvider.overrideWithValue(
      SystemdAutostart(executable: executable),
    ),
    environmentDiagnosticsProvider.overrideWithValue(const LinuxDiagnostics()),
  ];
}
