class Sent {
  Sent(this.at, this.kind, this.bytes, this.length);
  final DateTime at;
  final String kind;
  final List<int> bytes;
  final int length;
}
