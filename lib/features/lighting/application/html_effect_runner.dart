// Runs the installed HTML/Canvas effect and sends the sampled LED colors to the
// engine (plan §5.5).
//
// QuickJS runs in a child process in Linux app builds (an isolate in test and
// development runners); the canvas is rasterized on the UI isolate. Neither
// lives in the engine isolate. The effect renders at the effects FPS — even
// with the window hidden — and the engine only streams the colors to devices.
// Fans keep the 2 fps gap (`alv2SafeStreamGap`), so the hub does not lose RPM.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/engine/engine_host.dart';
import '../../monitoring/monitoring.dart';
import '../../preferences/preferences.dart';
import '../domain/effect_compat.dart' show EffectIssue;
import '../domain/effect_runtime.dart';
import '../domain/effect_sampling.dart';
import '../domain/installed_effect.dart';
import '../domain/light_device.dart';
import '../domain/lighting_config.dart';
import '../domain/rgb.dart';
import 'installed_effects_controller.dart';
import 'lighting_controller.dart';
import 'lighting_messages.dart';

part 'html_effect_runner.freezed.dart';

/// Why the HTML effect is not running. The presentation maps it to the
/// catalog (`LightingStrings.effectLoadFailed`/`effectPaused`/...).
enum HtmlEffectIssue { loadFailed, paused, unsupported }

@freezed
abstract class HtmlEffectStatus with _$HtmlEffectStatus {
  const factory HtmlEffectStatus({
    /// Global effect id (`html:<id>`) currently rendered.
    String? effectId,
    @Default(false) bool loading,

    /// Reason the effect is not running; [error] carries technical detail.
    HtmlEffectIssue? issue,

    /// Duration of the frame that paused the effect, for
    /// [HtmlEffectIssue.paused].
    @Default(0) int slowFrameMs,

    /// Host features the effect needs, for [HtmlEffectIssue.unsupported].
    @Default(<EffectIssue>[]) List<EffectIssue> missingFeatures,
    String? error,

    /// Measured render FPS and mean frame time of the last second.
    @Default(0) double fps,
    @Default(0) double frameMs,
  }) = _HtmlEffectStatus;
}

extension HtmlEffectStatusX on HtmlEffectStatus {
  /// Stopped because frames take too long (an effect stuck in a loop).
  bool get paused => issue == HtmlEffectIssue.paused;

  bool get running => effectId != null && !loading && issue == null;
}

/// Longest accepted frame. Above this for [maxSlowFrames] in a row the effect
/// is paused and marked. A script that never returns is killed at the worker
/// hard limit (`scriptHardLimit`, in html_effects/runtime.dart).
const slowFrameLimit = Duration(milliseconds: 250);
const maxSlowFrames = 3;

/// Last rendered frame, for the canvas preview. The runner updates it at the
/// effects FPS; only the painter listens, so it does not rebuild the page.
final htmlEffectFramesProvider = Provider<ValueNotifier<EffectFrame?>>((ref) {
  final notifier = ValueNotifier<EffectFrame?>(null);
  ref.onDispose(notifier.dispose);
  return notifier;
});

class HtmlEffectRunner extends Notifier<HtmlEffectStatus> {
  EffectRuntime? _runtime;
  ValueNotifier<EffectFrame?>? _liveFrame;
  Timer? _timer;
  int _generation = 0;
  String? _slug;
  String? _effectId;
  bool _busy = false;
  bool _thumbnailSaved = false;
  int _slowFrames = 0;

  DateTime _started = DateTime.now();
  DateTime _fpsWindow = DateTime.now();
  int _frames = 0;
  int _frameUs = 0;
  Map<String, Object?>? _valuesSent;
  SensorSample? _sensorsSent;

  /// Config the sampling points were last built from; the points only change
  /// with the devices (modes, quantity, placement), not with every frame.
  LightingConfig? _sampleConfig;

  @override
  HtmlEffectStatus build() {
    _liveFrame = ref.watch(htmlEffectFramesProvider);
    final effectId = ref.watch(lightingProvider.select((c) => c.effectId));
    final fps = ref.watch(preferencesProvider.select((p) => p.effectsFps));
    ref.onDispose(_stop);
    _stop();
    final slug = htmlEffectSlugOf(effectId);
    if (slug == null) return const HtmlEffectStatus();
    final gen = _generation;
    unawaited(_open(gen, slug, effectId, fps));
    return HtmlEffectStatus(effectId: effectId, loading: true);
  }

  Future<void> _open(int gen, String slug, String effectId, int fps) async {
    try {
      final library = ref.read(effectLibraryProvider);
      final effect = await library.find(slug);
      if (effect == null) throw StateError('installed effect not found');
      if (!effect.canRun) {
        _showUnsupported(gen, effectId, effect);
        return;
      }
      final html = await library.readHtml(slug);
      final values =
          ref.read(lightingProvider).effectValues[effectId] ?? const {};
      final runtime = await ref
          .read(effectRuntimeFactoryProvider)
          .load(html, values: values);
      if (gen != _generation) {
        runtime.dispose();
        return;
      }
      _start(effectId, slug, runtime, values, fps);
    } on Object catch (e) {
      if (gen == _generation) {
        state = HtmlEffectStatus(
          effectId: effectId,
          issue: HtmlEffectIssue.loadFailed,
          error: '$e',
        );
      }
    }
  }

  void _showUnsupported(int gen, String effectId, InstalledEffect effect) {
    if (gen != _generation) return;
    state = HtmlEffectStatus(
      effectId: effectId,
      issue: HtmlEffectIssue.unsupported,
      missingFeatures: effect.compatibility.issues,
    );
  }

  /// Publishes the loaded runtime and starts the frame timer.
  void _start(
    String effectId,
    String slug,
    EffectRuntime runtime,
    Map<String, Object?> values,
    int fps,
  ) {
    _runtime = runtime;
    _slug = slug;
    _effectId = effectId;
    _valuesSent = values;
    _sampleConfig = null;
    _thumbnailSaved = false;
    _slowFrames = 0;
    _started = _fpsWindow = DateTime.now();
    _frames = 0;
    _frameUs = 0;
    state = HtmlEffectStatus(effectId: effectId);
    _timer = Timer.periodic(
      Duration(microseconds: 1000000 ~/ fps.clamp(5, 120)),
      (_) => unawaited(_tick()),
    );
  }

  Future<void> _tick() async {
    final gen = _generation;
    final runtime = _runtime;
    final effectId = _effectId;
    if (runtime == null || effectId == null || _busy) return;
    if (!ref.mounted) return;
    if (ref.read(lightingProvider).effectId != effectId) return;
    _busy = true;
    final sw = Stopwatch()..start();
    try {
      final cfg = ref.read(lightingProvider);
      _pushInputs(runtime, effectId, cfg);
      final (frame, colors) = await runtime.renderSampled(
        DateTime.now().difference(_started).inMicroseconds / 1000,
      );
      // The effect may have been switched while awaiting the frame.
      if (!_isCurrent(gen, runtime, effectId)) return;
      _publishFrame(effectId, runtime, cfg, frame, colors);
      _countFrame(sw.elapsed);
    } on Object catch (e) {
      // The effect may have been switched off while this frame was running.
      if (_isCurrent(gen, runtime, effectId)) _fail('$e');
    } finally {
      if (gen == _generation) _busy = false;
    }
  }

  /// Sends the effect values, LED positions, and sensors to the runtime when
  /// they changed since the previous frame.
  void _pushInputs(EffectRuntime runtime, String effectId, LightingConfig cfg) {
    final raw = cfg.effectValues[effectId] ?? const <String, Object?>{};
    if (!identical(raw, _valuesSent)) {
      for (final e in raw.entries) {
        runtime.setProperty(e.key, e.value);
      }
      _valuesSent = raw;
    }
    // The render worker samples the LEDs once it knows the LED positions;
    // the app samples from the frame itself when it does not (see the
    // `colors == null` fallback in [_publishFrame]).
    if (!identical(_sampleConfig, cfg)) {
      runtime.setSamplePoints(canvasSamplePoints(cfg));
      _sampleConfig = cfg;
    }
    final sample = ref.read(monitoringProvider).latest;
    if (sample != null && !identical(sample, _sensorsSent)) {
      runtime.setSensors(sample.values);
      _sensorsSent = sample;
    }
  }

  /// The render, the config, and the selected effect still match this tick.
  bool _isCurrent(int gen, EffectRuntime runtime, String effectId) =>
      ref.mounted &&
      gen == _generation &&
      identical(runtime, _runtime) &&
      ref.read(lightingProvider).effectId == effectId;

  void _publishFrame(
    String effectId,
    EffectRuntime runtime,
    LightingConfig cfg,
    EffectFrame frame,
    Map<LightDeviceId, List<Rgb>>? colors,
  ) {
    ref
        .read(engineProvider)
        .send(
          SetHtmlEffectFrame(effectId, colors ?? sampleEffectFrame(cfg, frame)),
        );
    _liveFrame?.value = frame;
    if (!_thumbnailSaved) {
      _thumbnailSaved = true;
      unawaited(_saveThumbnail(runtime));
    }
  }

  void _countFrame(Duration took) {
    _frames++;
    _frameUs += took.inMicroseconds;
    if (took > slowFrameLimit) {
      _slowFrames++;
      if (_slowFrames >= maxSlowFrames) {
        _pause((took.inMicroseconds / 1000).round());
        return;
      }
    } else {
      _slowFrames = 0;
    }
    final elapsed = DateTime.now().difference(_fpsWindow);
    if (elapsed < const Duration(seconds: 1)) return;
    final fps = _frames * 1000000 / elapsed.inMicroseconds;
    final ms = _frames == 0 ? 0.0 : _frameUs / _frames / 1000;
    _frames = 0;
    _frameUs = 0;
    _fpsWindow = DateTime.now();
    state = state.copyWith(fps: fps, frameMs: ms);
  }

  Future<void> _saveThumbnail(EffectRuntime runtime) async {
    final slug = _slug;
    if (slug == null) return;
    try {
      final png = await runtime.snapshotPng();
      if (png != null) {
        await ref.read(effectLibraryProvider).saveThumbnail(slug, png);
      }
    } on Object catch (e) {
      debugPrint('effect thumbnail: $e');
    }
  }

  void _pause(int ms) {
    _release();
    state = state.copyWith(
      issue: HtmlEffectIssue.paused,
      slowFrameMs: ms,
      loading: false,
    );
  }

  void _fail(String detail) {
    _release();
    state = HtmlEffectStatus(
      effectId: _effectId,
      issue: HtmlEffectIssue.loadFailed,
      error: detail,
    );
  }

  /// Stops the render loop and frees the runtime and the preview frame.
  void _release() {
    _timer?.cancel();
    _timer = null;
    _runtime?.dispose();
    _runtime = null;
    _liveFrame?.value = null;
  }

  void _stop() {
    _generation++;
    _release();
    _slug = null;
    _effectId = null;
    _valuesSent = null;
    _busy = false;
  }
}

final htmlEffectRunnerProvider =
    NotifierProvider<HtmlEffectRunner, HtmlEffectStatus>(HtmlEffectRunner.new);
