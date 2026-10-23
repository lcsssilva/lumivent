/// Safety guard failure. The message is an English technical message.
class GpuGuardException implements Exception {
  const GpuGuardException(this.message);
  final String message;
  @override
  String toString() => 'GpuGuardException: $message';
}
