class AutostartState {
  const AutostartState({required this.enabled, required this.stale});
  final bool enabled;

  /// The installed unit points to another executable (for example, another build).
  final bool stale;
}
