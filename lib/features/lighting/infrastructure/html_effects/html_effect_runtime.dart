import 'dart:typed_data';
import 'dart:ui' as ui;

import '../../domain/effects/effect_source.dart';
import '../../domain/effects/effect_runtime.dart';
import '../../domain/canvas/effect_frame.dart';
import '../../domain/canvas/effect_sampling.dart';
import '../../domain/light_device.dart';
import '../../domain/rgb.dart';
import 'effect_rasterizer.dart';
import 'quickjs_effect.dart';

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

  /// Always returns the frame: the pixels are already on this isolate.
  @override
  Future<(EffectFrame, Map<LightDeviceId, List<Rgb>>?)> renderSampled(
    double nowMs, {
    bool needFrame = true,
  }) async {
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
