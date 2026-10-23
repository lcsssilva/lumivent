part of 'canvas_replayer.dart';

/// Accumulates opaque rectangles and draws them all with one `drawVertices`.
/// Only rectangles independent of alpha/blend and paths belong here.
class _RectBatch {
  static const _capacity = 512;

  final _positions = Float32List(_capacity * 12);
  final _colors = Int32List(_capacity * 6);
  int _count = 0;

  /// Adds [rect] with [color]; returns false when the batch is full.
  bool add(Rect r, Color color) {
    if (_count == _capacity) return false;
    final x0 = r.left, y0 = r.top, x1 = r.right, y1 = r.bottom;
    final o = _count * 12;
    final p = _positions;
    p[o] = x0;
    p[o + 1] = y0;
    p[o + 2] = x1;
    p[o + 3] = y0;
    p[o + 4] = x1;
    p[o + 5] = y1;
    p[o + 6] = x0;
    p[o + 7] = y0;
    p[o + 8] = x1;
    p[o + 9] = y1;
    p[o + 10] = x0;
    p[o + 11] = y1;
    final argb = color.toARGB32();
    final c = _count * 6;
    for (var i = 0; i < 6; i++) {
      _colors[c + i] = argb;
    }
    _count++;
    return true;
  }

  void draw(Canvas canvas, Paint paint) {
    if (_count == 0) return;
    final positions = Float32List.sublistView(_positions, 0, _count * 12);
    final colors = Int32List.sublistView(_colors, 0, _count * 6);
    final vertices = Vertices.raw(
      VertexMode.triangles,
      positions,
      colors: colors,
    );
    canvas.drawVertices(vertices, BlendMode.srcOver, paint);
    vertices.dispose();
    _count = 0;
  }
}
