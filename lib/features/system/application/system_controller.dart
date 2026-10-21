import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../devices/devices.dart' show devicesProvider;
import '../domain/autostart.dart';
import '../domain/diagnostics.dart';

final autostartServiceProvider = Provider<AutostartService>(
  (ref) => throw UnimplementedError('autostartServiceProvider'),
);
final environmentDiagnosticsProvider = Provider<EnvironmentDiagnostics>(
  (ref) => throw UnimplementedError('environmentDiagnosticsProvider'),
);

class AutostartController extends AsyncNotifier<AutostartState> {
  @override
  Future<AutostartState> build() => ref.read(autostartServiceProvider).status();

  Future<void> setEnabled(bool on) async {
    final svc = ref.read(autostartServiceProvider);
    state = await AsyncValue.guard(() async {
      on ? await svc.enable() : await svc.disable();
      return svc.status();
    });
  }
}

final autostartProvider =
    AsyncNotifierProvider<AutostartController, AutostartState>(
      AutostartController.new,
    );

final diagnosticsProvider = Provider<List<DiagnosticCheck>>((ref) {
  // Recomputed along with each device scan.
  ref.watch(devicesProvider);
  return ref.watch(environmentDiagnosticsProvider).run();
});
