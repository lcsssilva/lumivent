import 'diagnostic_check.dart';

/// Port for environment checks.
abstract interface class EnvironmentDiagnostics {
  List<DiagnosticCheck> run();
}
