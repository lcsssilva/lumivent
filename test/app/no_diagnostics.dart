import 'package:lumivent/features/system/system.dart';

class NoDiagnostics implements EnvironmentDiagnostics {
  @override
  List<DiagnosticCheck> run() => const [];
}
