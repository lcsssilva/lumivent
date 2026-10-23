// System power events port (pure Dart).

/// Observes PC suspend, resume, and shutdown so the module can turn ARGB off
/// before sleep (a "shutdown color").
abstract interface class PowerWatcher {
  /// Starts observing.
  ///
  /// [beforeSleep]: the system is about to suspend/hibernate; logind waits for
  /// it to finish ("delay" inhibitor), so it must be fast.
  /// [afterResume]: the system resumed from suspend.
  /// [beforeShutdown]: the system is about to power off or reboot.
  ///
  /// Never throws: without a bus/logind, the implementation logs and continues.
  Future<void> start({
    required Future<void> Function() beforeSleep,
    required void Function() afterResume,
    required Future<void> Function() beforeShutdown,
  });

  /// Stops observing and releases the inhibitor.
  Future<void> stop();
}
