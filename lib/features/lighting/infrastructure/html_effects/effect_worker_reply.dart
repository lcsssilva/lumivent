/// A reply parsed from an envelope. `ok` true means done ([payload] is the
/// result); false means failed ([payload] is the error pair.
final class EffectWorkerReply {
  EffectWorkerReply._(this.id, this.ok, this.payload);

  /// Parses [message] as a reply envelope; `null` when it is not valid, so
  /// the caller drops it instead of failing every pending request.
  static EffectWorkerReply? tryParse(Object? message) {
    if (message is! List || message.length < 3) return null;
    final id = message[0];
    final ok = message[1];
    if (id is! int || ok is! bool) return null;
    return EffectWorkerReply._(id, ok, message[2]);
  }

  final int id;
  final bool ok;
  final Object? payload;

  /// Message of an error payload ('the message first, then the stack').
  String get errorMessage {
    final detail = payload;
    return detail is List && detail.isNotEmpty ? '${detail[0]}' : '$detail';
  }
}
