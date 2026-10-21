// Replays the commands recorded by canvas2d_shim.js into a dart:ui Canvas.

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'canvas_buffer.dart';
import 'css_color.dart';
import 'hsl_color.dart';

class _State {
  _State();
  _State.copy(_State o)
    : fill = o.fill,
      stroke = o.stroke,
      lineWidth = o.lineWidth,
      alpha = o.alpha,
      blend = o.blend,
      cap = o.cap,
      join = o.join;

  Object fill = const Color(0xFF000000); // Color or _Gradient
  Object stroke = const Color(0xFF000000);
  double lineWidth = 1;
  double alpha = 1;
  BlendMode blend = BlendMode.srcOver;
  StrokeCap cap = StrokeCap.butt;
  StrokeJoin join = StrokeJoin.miter;
}

class _Gradient {
  _Gradient.linear(this.args) : radial = false;
  _Gradient.radial(this.args) : radial = true;

  final bool radial;
  final List<double> args;
  final stops = <(double, Color)>[];

  Shader shader() {
    final s = [...stops]..sort((a, b) => a.$1.compareTo(b.$1));
    final colors = s.isEmpty
        ? const [Color(0x00000000), Color(0x00000000)]
        : [for (final e in s) e.$2];
    final pos = s.isEmpty
        ? const [0.0, 1.0]
        : [for (final e in s) e.$1.clamp(0.0, 1.0)];
    if (colors.length == 1) {
      colors.add(colors.first);
      pos.add(1.0);
    }
    if (!radial) {
      return Gradient.linear(
        Offset(args[0], args[1]),
        Offset(args[2], args[3]),
        colors,
        pos,
      );
    }
    // createRadialGradient(x0,y0,r0, x1,y1,r1): Skia focuses at (x0,y0).
    return Gradient.radial(
      Offset(args[3], args[4]),
      args[5],
      colors,
      pos,
      TileMode.clamp,
      null,
      Offset(args[0], args[1]),
      args[2],
    );
  }
}

const _blendModes = <String, BlendMode>{
  'source-over': BlendMode.srcOver,
  'source-in': BlendMode.srcIn,
  'source-out': BlendMode.srcOut,
  'source-atop': BlendMode.srcATop,
  'destination-over': BlendMode.dstOver,
  'destination-in': BlendMode.dstIn,
  'destination-out': BlendMode.dstOut,
  'destination-atop': BlendMode.dstATop,
  'lighter': BlendMode.plus,
  'copy': BlendMode.src,
  'xor': BlendMode.xor,
  'multiply': BlendMode.multiply,
  'screen': BlendMode.screen,
  'overlay': BlendMode.overlay,
  'darken': BlendMode.darken,
  'lighten': BlendMode.lighten,
  'color-dodge': BlendMode.colorDodge,
  'color-burn': BlendMode.colorBurn,
  'hard-light': BlendMode.hardLight,
  'soft-light': BlendMode.softLight,
  'difference': BlendMode.difference,
  'exclusion': BlendMode.exclusion,
  'hue': BlendMode.hue,
  'saturation': BlendMode.saturation,
  'color': BlendMode.color,
  'luminosity': BlendMode.luminosity,
};

/// State that survives between frames: gradients and the context state
/// (JS only sends changes).
class CanvasReplayer {
  CanvasReplayer({this.width = 320, this.height = 200});

  final double width, height;
  final _gradients = <int, _Gradient>{};
  var _st = _State();
  final _stack = <_State>[];
  final _fillPaint = Paint();
  final _strokePaint = Paint();
  final _vertexPaint = Paint()..isAntiAlias = false;

  /// Commands the replay did not recognize (for the compatibility indicator).
  final unknownOps = <String>{};

  void replay(Canvas canvas, CanvasCommandBuffer ops) {
    var path = Path();
    canvas.save();
    // JS saves stay inside this one; the final restore undoes anything left.
    var depth = 0;
    final batch = _RectBatch();
    void flushBatch() => batch.draw(canvas, _vertexPaint);

    while (ops.next()) {
      double a(int i) => ops.number(i);
      // Consecutive opaque rectangles become a single drawVertices; any other
      // command flushes the batch to preserve draw order.
      switch (ops.opcode) {
        case CanvasOp.fillStyle:
        case CanvasOp.strokeStyle:
        case CanvasOp.lineWidth:
          break;
        default:
          flushBatch();
      }
      switch (ops.opcode) {
        case CanvasOp.fillStyle:
          _st.fill = _style(ops) ?? _st.fill;
        case CanvasOp.hslStyle:
          _st.fill = Color(hslArgb(a(0), a(1), a(2)));
        case CanvasOp.strokeStyle:
          _st.stroke = _style(ops) ?? _st.stroke;
        case CanvasOp.lineWidth:
          final w = a(0);
          if (w > 0 && w.isFinite) _st.lineWidth = w;
        case CanvasOp.alpha:
          final v = a(0);
          if (v >= 0 && v <= 1) _st.alpha = v;
        case CanvasOp.composite:
          _st.blend = _blendModes[ops.text(0)] ?? _st.blend;
        case CanvasOp.lineCap:
          _st.cap = switch (ops.text(0)) {
            'round' => StrokeCap.round,
            'square' => StrokeCap.square,
            _ => StrokeCap.butt,
          };
        case CanvasOp.lineJoin:
          _st.join = switch (ops.text(0)) {
            'round' => StrokeJoin.round,
            'bevel' => StrokeJoin.bevel,
            _ => StrokeJoin.miter,
          };
        case CanvasOp.save:
          _stack.add(_State.copy(_st));
          canvas.save();
          depth++;
        case CanvasOp.restore:
          if (depth > 0) {
            _st = _stack.removeLast();
            canvas.restore();
            depth--;
          }
        case CanvasOp.translate:
          canvas.translate(a(0), a(1));
        case CanvasOp.rotate:
          canvas.rotate(a(0));
        case CanvasOp.scale:
          canvas.scale(a(0), a(1));
        case CanvasOp.transform:
          canvas.transform(_matrix(a(0), a(1), a(2), a(3), a(4), a(5)));
        case CanvasOp.setTransform:
          // setTransform is absolute: reset to identity, then apply the matrix.
          final cur = canvas.getTransform();
          final inv = _invert(cur);
          if (inv != null) canvas.transform(inv);
          canvas.transform(_matrix(a(0), a(1), a(2), a(3), a(4), a(5)));
        case CanvasOp.clearRect:
          canvas.drawRect(
            Rect.fromLTWH(a(0), a(1), a(2), a(3)),
            Paint()..blendMode = BlendMode.clear,
          );
        case CanvasOp.fillRect:
          final style = _st.fill;
          final rect = Rect.fromLTWH(a(0), a(1), a(2), a(3));
          if (_st.blend == BlendMode.srcOver &&
              _st.alpha == 1 &&
              style is Color &&
              style.a == 1) {
            if (!batch.add(rect, style)) {
              flushBatch();
              batch.add(rect, style);
            }
          } else {
            canvas.drawRect(rect, _paint(fill: true));
          }
        case CanvasOp.fillRect16:
          final color = Color(ops.color(4));
          final rect = Rect.fromLTWH(a(0), a(1), a(2), a(3));
          if (_st.blend == BlendMode.srcOver &&
              _st.alpha == 1 &&
              color.a == 1) {
            if (!batch.add(rect, color)) {
              flushBatch();
              batch.add(rect, color);
            }
          } else {
            canvas.drawRect(rect, Paint()..color = color);
          }
        case CanvasOp.fillRect16Hsl:
          final color = Color(hslArgb(a(4), a(5), a(6)));
          final rect = Rect.fromLTWH(a(0), a(1), a(2), a(3));
          if (_st.blend == BlendMode.srcOver && _st.alpha == 1) {
            if (!batch.add(rect, color)) {
              flushBatch();
              batch.add(rect, color);
            }
          } else {
            canvas.drawRect(rect, Paint()..color = color);
          }
        case CanvasOp.strokeRect:
          canvas.drawRect(
            Rect.fromLTWH(a(0), a(1), a(2), a(3)),
            _paint(fill: false),
          );
        case CanvasOp.beginPath:
          path = Path();
        case CanvasOp.closePath:
          path.close();
        case CanvasOp.moveTo:
          path.moveTo(a(0), a(1));
        case CanvasOp.lineTo:
          path.lineTo(a(0), a(1));
        case CanvasOp.rect:
          path.addRect(Rect.fromLTWH(a(0), a(1), a(2), a(3)));
          path.moveTo(a(0), a(1));
        case CanvasOp.arc:
          _arc(path, a(0), a(1), a(2), a(2), 0, a(3), a(4), a(5) == 1);
        case CanvasOp.ellipse:
          _arc(path, a(0), a(1), a(2), a(3), a(4), a(5), a(6), a(7) == 1);
        case CanvasOp.quadratic:
          path.quadraticBezierTo(a(0), a(1), a(2), a(3));
        case CanvasOp.bezier:
          path.cubicTo(a(0), a(1), a(2), a(3), a(4), a(5));
        case CanvasOp.fill:
          canvas.drawPath(path, _paint(fill: true));
        case CanvasOp.stroke:
          canvas.drawPath(path, _paint(fill: false));
        case CanvasOp.clip:
          canvas.clipPath(path);
        case CanvasOp.linearGradient:
          _gradients[a(0).toInt()] = _Gradient.linear([
            for (var i = 1; i < 5; i++) a(i),
          ]);
        case CanvasOp.radialGradient:
          _gradients[a(0).toInt()] = _Gradient.radial([
            for (var i = 1; i < 7; i++) a(i),
          ]);
        case CanvasOp.colorStop:
          final c = parseCssColor(ops.text(2));
          if (c != null) _gradients[a(0).toInt()]?.stops.add((a(1), c));
        case CanvasOp.unknown:
          unknownOps.add(ops.text(0));
        default:
          unknownOps.add('op${ops.opcode}');
      }
    }
    flushBatch();
    while (depth-- > 0) {
      _st = _stack.removeLast();
      canvas.restore();
    }
    canvas.restore();
  }

  Object? _style(CanvasCommandBuffer op) {
    if (op.isGradient(0)) return _gradients[op.number(0).toInt()];
    if (op.isColor(0)) return Color(op.color(0));
    return parseCssColor(op.text(0));
  }

  Paint _paint({required bool fill}) {
    final style = fill ? _st.fill : _st.stroke;
    final p = fill ? _fillPaint : _strokePaint;
    p
      ..isAntiAlias = true
      ..blendMode = _st.blend
      ..style = fill ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = _st.lineWidth
      ..strokeCap = _st.cap
      ..strokeJoin = _st.join
      ..shader = null;
    if (style is Color) {
      p.color = _st.alpha == 1
          ? style
          : style.withValues(alpha: style.a * _st.alpha);
    } else if (style is _Gradient) {
      p.shader = style.shader();
      p.color = Color.fromRGBO(0, 0, 0, _st.alpha);
    }
    return p;
  }

  static void _arc(
    Path path,
    double cx,
    double cy,
    double rx,
    double ry,
    double rot,
    double a0,
    double a1,
    bool ccw,
  ) {
    if (rx < 0 || ry < 0) return;
    const tau = 2 * math.pi;
    var sweep = a1 - a0;
    if (!ccw) {
      sweep = sweep >= tau ? tau : (sweep % tau + tau) % tau;
    } else {
      sweep = sweep <= -tau ? -tau : -(((a0 - a1) % tau + tau) % tau);
    }
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: rx * 2,
      height: ry * 2,
    );
    final arc = Path();
    // Skia does not draw a 360° arc in one call: split it into two.
    if (sweep.abs() >= tau - 1e-9) {
      arc.arcTo(rect, a0, sweep / 2, true);
      arc.arcTo(rect, a0 + sweep / 2, sweep / 2, false);
    } else {
      arc.arcTo(rect, a0, sweep, true);
    }
    final m = _matrix(
      math.cos(rot),
      math.sin(rot),
      -math.sin(rot),
      math.cos(rot),
      cx,
      cy,
    );
    path.extendWithPath(arc, Offset.zero, matrix4: m);
  }
}

Float64List _matrix(
  double a,
  double b,
  double c,
  double d,
  double e,
  double f,
) => Float64List.fromList([a, b, 0, 0, c, d, 0, 0, 0, 0, 1, 0, e, f, 0, 1]);

/// Inverse of a 4×4 matrix containing only the 2D affine part.
Float64List? _invert(Float64List m) {
  final a = m[0], b = m[1], c = m[4], d = m[5], e = m[12], f = m[13];
  final det = a * d - b * c;
  if (det == 0) return null;
  final ia = d / det, ib = -b / det, ic = -c / det, id = a / det;
  return _matrix(ia, ib, ic, id, -(ia * e + ic * f), -(ib * e + id * f));
}

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
