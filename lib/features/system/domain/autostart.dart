// System module domain (pure Dart): user-session integration.

class AutostartState {
  const AutostartState({required this.enabled, required this.stale});
  final bool enabled;

  /// The installed unit points to another executable (for example, another build).
  final bool stale;
}

/// Autostart port for the operating system.
abstract interface class AutostartService {
  /// Where the configuration is stored (shown to the user).
  String get location;
  Future<AutostartState> status();
  Future<void> enable();
  Future<void> disable();
}
