// Replays canvas commands and readbacks a frame. Main isolate only.
//
// The fast path ([SimpleCanvasRaster.tryRaster]) keeps the pixels only; the
// general path draws with dart:ui for the frames it cannot fast-raster.

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import '../../domain/effect_frame.dart';
import 'canvas_command_buffer.dart';
import 'canvas_replayer.dart';
import 'effect_script_exception.dart' show EffectScriptException;
import 'simple_canvas_raster.dart';
import 'simple_raster_state.dart';

/// Formats a frame from canvas command buffers (and keeps the last frame for
/// preview and snapshot).
class EffectRasterizer {
  static const width = 320, height = 200;

  final _replayer = CanvasReplayer(
    width: width.toDouble(),
    height: height.toDouble(),
  );
  ui.Image? _frame;
  Uint32List? _simplePixels;
  SimpleRasterState _simpleState = const SimpleRasterState();
  ui.Image? _preview;
  bool _decodingPreview = false;
  DateTime _lastPreviewAt = DateTime.fromMillisecondsSinceEpoch(0);
  int lastOpCount = 0;
  Duration lastRasterTime = Duration.zero, lastReadbackTime = Duration.zero;

  Set<String> get unknownOps => _replayer.unknownOps;

  /// The fast frames accepted by [acceptSimple], for preview and snapshot.
  Uint32List? get simplePixels => _simplePixels;

  ui.Image? get image {
    final pixels = _simplePixels;
    if (pixels != null) {
      final now = DateTime.now();
      if (!_decodingPreview &&
          now.difference(_lastPreviewAt) > const Duration(milliseconds: 100)) {
        _lastPreviewAt = now;
        _decodingPreview = true;
        _decode(pixels).then(
          (img) {
            if (!_decodingPreview) {
              img.dispose();
              return;
            }
            _preview?.dispose();
            _preview = img;
            _decodingPreview = false;
          },
          onError: (Object _) {
            _decodingPreview = false;
          },
        );
      }
      return _preview;
    }
    return _frame;
  }

  /// Accepts a frame already rasterized on the render isolate (the fast
  /// path): the runtime only formats the RGBA bytes ([rgba]) and keeps the
  /// pixels for preview and snapshot. No raster work reaches the UI isolate.
  EffectFrame acceptSimple(Uint8List rgba, int opCount) {
    lastRasterTime = Duration.zero;
    lastReadbackTime = Duration.zero;
    lastOpCount = opCount;
    _frame?.dispose();
    _frame = null;
    _simplePixels = Uint32List.view(
      rgba.buffer,
      rgba.offsetInBytes,
      rgba.lengthInBytes >> 2,
    );
    return EffectFrame(width, height, rgba);
  }

  Future<EffectFrame> draw(Uint8List encoded) async {
    final simple = SimpleCanvasRaster.tryRaster(
      encoded,
      previous: _simplePixels,
      state: _simpleState,
      // A general-replay frame left the retained pixels in _frame only.
      mustCover: _simplePixels == null && _frame != null,
    );
    if (simple != null) {
      final frame = acceptSimple(simple.rgba, simple.opCount);
      _simpleState = simple.state;
      return frame;
    }
    return drawSlow(encoded);
  }

  /// General dart:ui replay, for frames the fast path cannot draw.
  Future<EffectFrame> drawSlow(Uint8List encoded) async {
    final sw = Stopwatch()..start();
    // After fast frames the retained canvas lives only in the pixels: decode
    // it so the replay draws on top of it, as the browser would.
    final retained = _simplePixels;
    if (_frame == null && retained != null) _frame = await _decode(retained);
    _simplePixels = null;
    _simpleState = SimpleCanvasRaster.stateAfterReplay(encoded, _simpleState);
    _preview?.dispose();
    _preview = null;
    final ops = CanvasCommandBuffer(encoded);
    sw.reset();
    final rec = ui.PictureRecorder();
    final canvas = ui.Canvas(
      rec,
      ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    );
    // The browser canvas preserves content between frames (Neon Shift relies
    // on this): start from the previous image.
    final prev = _frame;
    if (prev != null) {
      canvas.drawImage(
        prev,
        ui.Offset.zero,
        ui.Paint()..blendMode = ui.BlendMode.src,
      );
    }
    _replayer.replay(canvas, ops);
    final pic = rec.endRecording();
    final img = await pic.toImage(width, height);
    pic.dispose();
    lastRasterTime = sw.elapsed;
    lastOpCount = ops.count;

    sw.reset();
    final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    lastReadbackTime = sw.elapsed;
    prev?.dispose();
    _frame = img;
    if (data == null) {
      throw const EffectScriptException('frame read failed');
    }
    return EffectFrame(
      width,
      height,
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  }

  Future<Uint8List?> snapshotPng() async {
    final pixels = _simplePixels;
    if (pixels != null) {
      final img = await _decode(pixels);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      img.dispose();
      if (png == null) return null;
      return png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes);
    }
    final png = await _frame?.toByteData(format: ui.ImageByteFormat.png);
    if (png == null) return null;
    return png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes);
  }

  Future<ui.Image> _decode(Uint32List pixels) {
    final done = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      Uint8List.view(pixels.buffer, pixels.offsetInBytes, pixels.lengthInBytes),
      width,
      height,
      ui.PixelFormat.rgba8888,
      done.complete,
    );
    return done.future;
  }

  void dispose() {
    _frame?.dispose();
    _frame = null;
    _preview?.dispose();
    _preview = null;
    // A decode still in flight sees this and disposes its image.
    _decodingPreview = false;
    _simplePixels = null;
    _simpleState = const SimpleRasterState();
  }
}
