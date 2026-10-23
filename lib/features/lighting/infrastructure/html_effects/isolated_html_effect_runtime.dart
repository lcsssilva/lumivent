import 'dart:typed_data';
import 'dart:ui' as ui;

import '../../domain/effects/effect_meta.dart';
import '../../domain/effects/effect_source.dart';
import '../../domain/effects/effect_runtime.dart';
import '../../domain/canvas/effect_frame.dart';
import '../../domain/light_device.dart';
import '../../domain/rgb.dart';
import 'effect_rasterizer.dart';
import 'effect_worker_protocol.dart';
import 'quickjs_effect.dart';
import 'effect_script_exception.dart';
import 'shared_effect_worker.dart';
import 'simple_canvas_raster.dart' show SimpleCanvasRaster;

/// Runtime used by the app: QuickJS in a worker that can be killed when a frame
/// exceeds [scriptHardLimit] or the effect throws. The fast raster path also
/// runs there (a simple canvas is mutated in place and published per frame),
/// so the UI isolate only forwards the RGBA bytes.
class IsolatedHtmlEffectRuntime implements EffectRuntime {
  static const _maxBufferedLogs = 200;

  IsolatedHtmlEffectRuntime._(this.effect, this._connection, this._raster);

  @override
  final EffectSource effect;
  final EffectWorkerLease _connection;
  final EffectRasterizer _raster;
  final _logs = <String>[];
  Duration _lastScriptTime = Duration.zero;

  static const width = EffectRasterizer.width;
  static const height = EffectRasterizer.height;

  int get lastOpCount => _raster.lastOpCount;
  Duration get lastScriptTime => _lastScriptTime;
  Duration get lastRasterTime => _raster.lastRasterTime;
  Duration get lastReadbackTime => _raster.lastReadbackTime;
  ui.Image? get preview => _raster.image;

  @override
  Set<String> get unknownOps => _raster.unknownOps;

  /// Loads [html] into [worker], or into a worker of its own that closes
  /// with this runtime when [worker] is null.
  static Future<IsolatedHtmlEffectRuntime> load(
    String html, {
    Map<String, Object?> values = const {},
    String? shim,
    SharedEffectWorker? worker,
  }) async {
    final effect = parseEffect(html);
    final shimScript = shim ?? await loadShim();
    final connection =
        await (worker ?? SharedEffectWorker(idleTimeout: Duration.zero))
            .acquire();
    try {
      await connection.request(
        loadRequest(html, shimScript, values),
        timeout: scriptLoadLimit,
      );
    } on Object {
      // A script error leaves the worker usable for the next effect; a load
      // past its deadline has already killed it.
      connection.release();
      rethrow;
    }
    return IsolatedHtmlEffectRuntime._(effect, connection, EffectRasterizer());
  }

  @override
  Future<EffectFrame> renderFrame(double nowMs) async =>
      (await renderSampled(nowMs)).$1!;

  @override
  Future<(EffectFrame?, Map<LightDeviceId, List<Rgb>>?)> renderSampled(
    double nowMs, {
    bool needFrame = true,
  }) async {
    final reply = await _connection.request(
      frameRequest(nowMs, pixels: needFrame),
      timeout: scriptHardLimit,
    ) as List;
    final frame = parseFrameReply(reply);
    _logs.addAll(frame.logs.take(_maxBufferedLogs));
    if (_logs.length > _maxBufferedLogs) {
      _logs.removeRange(0, _logs.length - _maxBufferedLogs);
    }
    _lastScriptTime = frame.scriptTime;
    if (!frame.simple) {
      // General replay on the UI isolate: no sampling available, the app
      // samples from the returned frame itself.
      return (await _raster.drawSlow(frame.pixelsOrOps), null);
    }
    final colors = frame.colors;
    if (!needFrame && colors != null && frame.pixelsOrOps.isEmpty) {
      // The worker sampled the LEDs and left the unused pixels out.
      return (null, colors);
    }
    if (frame.pixelsOrOps.lengthInBytes !=
        SimpleCanvasRaster.width * SimpleCanvasRaster.height * 4) {
      throw const EffectScriptException('frame pixels have the wrong size');
    }
    return (
      _raster.acceptSimple(frame.pixelsOrOps, frame.opCount),
      // A null map (invalid reply payload) makes the app sample itself.
      frame.colors,
    );
  }

  @override
  void setSamplePoints(List<(LightDeviceId, int, int)>? points) =>
      _connection.send(pointsRequest(encodeSamplePoints(points)));

  @override
  void setProperty(String name, Object? value) =>
      _connection.send(propertyRequest(name, value));

  @override
  void setSensors(Map<String, double> values) {
    final clean = <String, double>{
      for (final e in values.entries)
        if (e.value.isFinite) e.key: e.value,
    };
    _connection.send(sensorsRequest(clean));
  }

  @override
  Future<Uint8List?> snapshotPng() => _raster.snapshotPng();

  @override
  List<String> drainLog() {
    final out = List<String>.of(_logs);
    _logs.clear();
    return out;
  }

  @override
  void dispose() {
    _connection.release();
    _raster.dispose();
  }
}
