/// B, G, and R positions in the packet (each CalStrip provides three bytes, ITE §1.3).
class IteColorOrder {
  const IteColorOrder(this.posB, this.posG, this.posR);

  /// From a CalStrip u32 little-endian: bytes `posB posG posR 00`.
  factory IteColorOrder.fromCalStrip(int v, IteColorOrder fallback) {
    final b = v & 0xFF, g = (v >> 8) & 0xFF, r = (v >> 16) & 0xFF;
    final o = IteColorOrder(b, g, r);
    return {b, g, r}.length == 3 && b < 3 && g < 3 && r < 3 ? o : fallback;
  }

  /// ARGB strips 5 V: G, R, B.
  static const grb = IteColorOrder(2, 0, 1);

  /// Board zones: B, G, R.
  static const bgr = IteColorOrder(0, 1, 2);

  final int posB, posG, posR;

  /// The three color bytes in wire order.
  List<int> bytes(int r, int g, int b) {
    final out = List<int>.filled(3, 0);
    out[posB] = b;
    out[posG] = g;
    out[posR] = r;
    return out;
  }

  @override
  bool operator ==(Object other) =>
      other is IteColorOrder &&
      other.posB == posB &&
      other.posG == posG &&
      other.posR == posR;

  @override
  int get hashCode => Object.hash(posB, posG, posR);

  @override
  String toString() => 'IteColorOrder(B@$posB G@$posG R@$posR)';
}
