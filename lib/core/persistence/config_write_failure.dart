/// A failure to persist the configuration file.
class ConfigWriteFailure implements Exception {
  const ConfigWriteFailure({
    required this.section,
    required this.cause,
    required this.stackTrace,
  });

  /// JSON section name that was being written; whole-file writes (import) are
  /// recorded as `configuration`.
  final String section;

  /// The original write error.
  final Object cause;
  final StackTrace stackTrace;

  @override
  String toString() => 'Failed to save $section: $cause';
}
