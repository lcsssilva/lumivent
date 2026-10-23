// Runs an HTML/Canvas effect on QuickJS (flutter_js) and draws each frame into
// a 320×200 ui.Image by replaying the binary canvas commands emitted by
// canvas2d_shim.js.
//
// This file holds the two runtimes used by the app and their factory; the
// pieces they share live in their own files:
//
// * `quickjs_effect.dart`: QuickJS evaluation and the script deadline limits.
// * `effect_rasterizer.dart`: frame rasterization (fast path and dart:ui
//   replay).
// * `effect_worker_protocol.dart`: named, validated worker message envelopes
//   and codecs.
// * `effect_worker.dart`: the worker side (child process and isolate).
// * `effect_worker_connection.dart`: the parent side of the worker transports.
//
// Linux app builds run QuickJS in a child process; tests and development
// runners use an isolate. Both paths enforce the evaluation deadlines, while
// the process boundary can also kill a native call stuck past its limit.

import 'dart:typed_data';
import 'dart:ui' as ui;

import '../../domain/effect_meta.dart';
import '../../domain/effect_runtime.dart';
import '../../domain/effect_sampling.dart';
import '../../domain/light_device.dart';
import '../../domain/rgb.dart';
import 'effect_rasterizer.dart';
import 'effect_worker_connection.dart';
import 'effect_worker_protocol.dart';
import 'quickjs_effect.dart';
import 'simple_canvas_raster.dart' show SimpleCanvasRaster;

export 'effect_worker.dart' show runHtmlEffectWorker;
export 'quickjs_effect.dart' show EffectScriptException;

/// Runtime used by the app: QuickJS in a worker that can be killed when a frame
/// exceeds [scriptHardLimit] or the effect throws. The fast raster path also
/// runs there (a simple canvas is mutated in place and published per frame),
/// so the UI isolate only forwards the RGBA bytes.
class IsolatedHtmlEffectRuntime implements EffectRuntime {
  static const _maxBufferedLogs = 200;

  IsolatedHtmlEffectRuntime._(this.effect, this._connection, this._raster);

  @override
  final EffectSource effect;
  final EffectWorkerConnection _connection;
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

  static Future<IsolatedHtmlEffectRuntime> load(
    String html, {
    Map<String, Object?> values = const {},
    String? shim,
  }) async {
    final effect = parseEffect(html);
    final connection = await EffectWorkerConnection.spawn();
    try {
      await connection.request(
        loadRequest(html, shim ?? await loadShim(), values),
        timeout: scriptLoadLimit,
      );
    } on Object {
      connection.close();
      rethrow;
    }
    return IsolatedHtmlEffectRuntime._(effect, connection, EffectRasterizer());
  }

  @override
  Future<EffectFrame> renderFrame(double nowMs) async =>
      (await renderSampled(nowMs)).$1;

  @override
  Future<(EffectFrame, Map<LightDeviceId, List<Rgb>>?)> renderSampled(
    double nowMs,
  ) async {
    final reply = await _connection.request(
      frameRequest(nowMs),
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
    _connection.close();
    _raster.dispose();
  }
}

/// Direct (same-isolate) runtime, used by the benchmark spike and tests.
class HtmlEffectRuntime implements EffectRuntime {
  HtmlEffectRuntime._(this.effect, this._js, this._raster);

  static const width = EffectRasterizer.width;
  static const height = EffectRasterizer.height;

  @override
  final EffectSource effect;
  final QuickJsEffect _js;
  final EffectRasterizer _raster;
  List<(LightDeviceId, int, int)>? _samplePoints;

  Duration lastRasterTime = Duration.zero, lastReadbackTime = Duration.zero;
  int lastOpCount = 0;

  Duration get lastScriptTime => _js.lastScriptTime;
  @override
  Set<String> get unknownOps => _raster.unknownOps;

  /// Last rendered frame (for previews and thumbnails).
  ui.Image? get preview => _raster.image;

  static Future<HtmlEffectRuntime> load(
    String html, {
    Map<String, Object?> values = const {},
    String? shim,
  }) async {
    final js = QuickJsEffect.load(html, shim ?? await loadShim(), values);
    return HtmlEffectRuntime._(js.effect, js, EffectRasterizer());
  }

  @override
  Future<EffectFrame> renderFrame(double nowMs) async =>
      (await renderSampled(nowMs)).$1;

  @override
  Future<(EffectFrame, Map<LightDeviceId, List<Rgb>>?)> renderSampled(
    double nowMs,
  ) async {
    final encoded = _js.renderOps(nowMs);
    final frame = await _raster.draw(encoded);
    lastOpCount = _raster.lastOpCount;
    lastRasterTime = _raster.lastRasterTime;
    lastReadbackTime = _raster.lastReadbackTime;
    final points = _samplePoints;
    final pixels = _raster.simplePixels;
    return (
      frame,
      points == null || pixels == null
          ? null
          : sampleCanvasPixels(points, pixels),
    );
  }

  @override
  void setSamplePoints(List<(LightDeviceId, int, int)>? points) =>
      _samplePoints = points;

  @override
  void setProperty(String name, Object? value) => _js.setProperty(name, value);

  @override
  void setSensors(Map<String, double> values) => _js.setSensors(values);

  @override
  Future<Uint8List?> snapshotPng() => _raster.snapshotPng();

  @override
  List<String> drainLog() => _js.drainLog();

  @override
  void dispose() {
    _raster.dispose();
    _js.dispose();
  }
}

/// Port implementation used by the UI (wired in `lighting_module.dart`).
class HtmlEffectRuntimeFactory implements EffectRuntimeFactory {
  const HtmlEffectRuntimeFactory();

  @override
  Future<EffectRuntime> load(
    String html, {
    Map<String, Object?> values = const {},
  }) => IsolatedHtmlEffectRuntime.load(html, values: values);
}
