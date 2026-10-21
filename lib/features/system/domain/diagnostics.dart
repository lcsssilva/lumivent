enum CheckState { ok, warn, pending }

/// Stable identity of a diagnostic check. The presentation owns the label and
/// the sentence built from [DiagnosticCheck.data] (plan D5).
enum DiagnosticId {
  udevRules,
  boardSensors,
  memorySmbus,
  memoryTemperature,
  nvmeHelper,
  hubRpmSync,
  hubArgbSync,
  lightingLoop,
}

/// An environment check (drivers, permissions, helpers).
///
/// [data] carries only technical values (paths, bus names, modules, loop
/// statistics); the UI translates and composes the text.
class DiagnosticCheck {
  const DiagnosticCheck(this.id, this.state, [this.data = const {}]);
  final DiagnosticId id;
  final CheckState state;
  final Map<String, Object?> data;
}

/// Port for environment checks.
abstract interface class EnvironmentDiagnostics {
  List<DiagnosticCheck> run();
}
