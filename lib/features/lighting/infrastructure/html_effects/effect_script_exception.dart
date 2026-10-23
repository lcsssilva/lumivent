/// A script (loading, framing, setup) failed or was interrupted.
class EffectScriptException implements Exception {
  const EffectScriptException(this.message);
  final String message;
  @override
  String toString() => 'EffectScriptException: $message';
}
