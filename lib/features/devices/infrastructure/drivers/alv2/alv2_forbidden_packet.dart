/// A packet the central guard refused to send.
class Alv2ForbiddenPacket implements Exception {
  Alv2ForbiddenPacket(this.reason);
  final String reason;
  @override
  String toString() => 'AL V2 packet blocked: $reason';
}
