import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../devices/devices.dart' show devicesProvider;
import '../domain/diagnostic_check.dart';
import '../domain/environment_diagnostics.dart';

final environmentDiagnosticsProvider = Provider<EnvironmentDiagnostics>(
  (ref) => throw UnimplementedError('environmentDiagnosticsProvider'),
);

final diagnosticsProvider = Provider<List<DiagnosticCheck>>((ref) {
  // Recomputed along with each device scan.
  ref.watch(devicesProvider);
  return ref.watch(environmentDiagnosticsProvider).run();
});
