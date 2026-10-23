class HidException implements Exception {
  HidException(this.message);
  final String message;
  @override
  String toString() => 'HidException: $message';
}
