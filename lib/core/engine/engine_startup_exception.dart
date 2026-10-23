/// The engine could not build or start its modules; it stopped the modules
/// that had started and exited.
class EngineStartupException implements Exception {
  const EngineStartupException(this.message);
  final String message;

  @override
  String toString() => 'Engine startup failed: $message';
}
