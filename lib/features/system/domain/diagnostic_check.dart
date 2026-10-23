import 'diagnostics.dart';
import 'diagnostic_data.dart';
import 'no_diagnostic_data.dart';

/// An environment check (drivers, permissions, helpers).
class DiagnosticCheck {
  const DiagnosticCheck(
    this.id,
    this.state, [
    this.data = const NoDiagnosticData(),
  ]);
  final DiagnosticId id;
  final CheckState state;
  final DiagnosticData data;
}
