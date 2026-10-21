// System module domain (pure Dart): user-session integration.

class AutostartState {
  const AutostartState({required this.enabled, required this.stale});
  final bool enabled;

  /// The installed unit points to another executable (for example, another build).
  final bool stale;
}

enum AutostartError { systemctlFailed }

/// A failed autostart operation. The UI translates [code] and shows the raw
/// command/stderr as technical detail.
class AutostartException implements Exception {
  AutostartException(this.code, {this.command = '', this.stderr = ''});
  final AutostartError code;
  final String command;
  final String stderr;
  @override
  String toString() => 'AutostartException(${code.name}: $command $stderr)';
}

/// Autostart port for the operating system.
abstract interface class AutostartService {
  /// Where the configuration is stored (shown to the user).
  String get location;
  Future<AutostartState> status();
  Future<void> enable();
  Future<void> disable();
}
