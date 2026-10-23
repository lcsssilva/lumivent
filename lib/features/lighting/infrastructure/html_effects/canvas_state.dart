part of 'canvas_replayer.dart';

class _CanvasState {
  _CanvasState();
  _CanvasState.copy(_CanvasState o)
    : fill = o.fill,
      stroke = o.stroke,
      lineWidth = o.lineWidth,
      alpha = o.alpha,
      blend = o.blend,
      cap = o.cap,
      join = o.join;

  Object fill = const Color(0xFF000000); // Color or _CanvasGradient
  Object stroke = const Color(0xFF000000);
  double lineWidth = 1;
  double alpha = 1;
  BlendMode blend = BlendMode.srcOver;
  StrokeCap cap = StrokeCap.butt;
  StrokeJoin join = StrokeJoin.miter;
}
