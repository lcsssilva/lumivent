part of 'led_canvas.dart';

class _LedCanvasState extends State<LedCanvas> {
  LightDeviceId? _drag;
  bool _resizing = false;
  Offset _start = Offset.zero;
  CanvasRect _startRect = const CanvasRect(0, 0, 1, 1);

  LightDeviceId? _hit(Offset p, double scale) {
    final cx = p.dx / scale, cy = p.dy / scale;
    for (final id in LightDeviceId.values.reversed) {
      if (!onCanvas(widget.config, id)) continue;
      final r = widget.config.device(id).placement;
      if (cx >= r.x && cx <= r.right && cy >= r.y && cy <= r.bottom) return id;
    }
    return null;
  }

  bool _onHandle(LightDeviceId id, Offset p, double scale) {
    final r = widget.config.device(id).placement;
    return (p.dx - r.right * scale).abs() <= _handlePx &&
        (p.dy - r.bottom * scale).abs() <= _handlePx;
  }

  void _panStart(Offset p, double scale) {
    final sel = widget.selected;
    LightDeviceId? id;
    var resizing = false;
    if (sel != null &&
        onCanvas(widget.config, sel) &&
        _onHandle(sel, p, scale)) {
      id = sel;
      resizing = true;
    } else {
      id = _hit(p, scale);
    }
    _drag = id;
    _resizing = resizing;
    _start = p;
    if (id != null) {
      _startRect = widget.config.device(id).placement;
      widget.onSelect(id);
    }
  }

  void _panUpdate(Offset p, double scale) {
    final id = _drag;
    if (id == null) return;
    final d = (p - _start) / scale;
    final r = _startRect;
    final next = _resizing
        ? CanvasRect(
            r.x,
            r.y,
            resizeExtent(r.w, d.dx, _minW, canvasWidth - r.x),
            resizeExtent(r.h, d.dy, _minH, canvasHeight - r.y),
          )
        : CanvasRect(
            (r.x + d.dx).clamp(0.0, canvasWidth - r.w),
            (r.y + d.dy).clamp(0.0, canvasHeight - r.h),
            r.w,
            r.h,
          );
    widget.onPlace(id, next);
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: canvasWidth / canvasHeight,
      child: LayoutBuilder(
        builder: (context, box) {
          final scale = box.maxWidth / canvasWidth;
          return GestureDetector(
            key: const ValueKey('led-canvas'),
            behavior: HitTestBehavior.opaque,
            // Report the pointer-down position so the corner resize handle is
            // tested where the user actually pressed, not after the pan slop.
            dragStartBehavior: DragStartBehavior.down,
            onTapDown: (d) => widget.onSelect(_hit(d.localPosition, scale)),
            onPanStart: (d) => _panStart(d.localPosition, scale),
            onPanUpdate: (d) => _panUpdate(d.localPosition, scale),
            onPanEnd: (_) => _drag = null,
            onPanCancel: () => _drag = null,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CustomPaint(
                painter: LedCanvasPainter(
                  config: widget.config,
                  selected: widget.selected,
                  time: widget.time,
                  frame: widget.frame,
                ),
                size: Size.infinite,
              ),
            ),
          );
        },
      ),
    );
  }
}
