enum CheckState { ok, warn, pending }

/// An environment check (drivers, permissions, helpers).
class DiagnosticCheck {
  const DiagnosticCheck(this.label, this.state, this.detail);
  final String label;
  final CheckState state;
  final String detail;
}

/// Port for environment checks.
abstract interface class EnvironmentDiagnostics {
  List<DiagnosticCheck> run();
}
