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

import '../../../core/engine/engine_host.dart';
import '../../monitoring/monitoring.dart';
import '../../preferences/preferences.dart';
import '../domain/effect_runtime.dart';
import '../domain/effect_sampling.dart';
import '../domain/installed_effect.dart';
import '../domain/lighting_config.dart';
import 'effects_controller.dart';
import 'lighting_controller.dart';
import 'lighting_messages.dart';

/// Why the HTML effect is not running. The presentation maps it to the
/// catalog (`LightingStrings.effectLoadFailed`/`effectPaused`/...).

enum HtmlEffectIssue { loadFailed, paused, unsupported }

class HtmlEffectStatus {
  const HtmlEffectStatus({
    this.effectId,
    this.loading = false,
    this.paused = false,
    this.issue,
    this.issueArgs = const [],
    this.error,
    this.fps = 0,
    this.frameMs = 0,
  });

  /// Global effect id (`html:<id>`) currently rendered.
  final String? effectId;
  final bool loading;

  /// Stopped because frames take too long (an effect stuck in a loop).
  final bool paused;

  /// Reason the effect is not running; [error] carries technical detail.
  final HtmlEffectIssue? issue;
  final List<String> issueArgs;
  final String? error;

  /// Measured render FPS and mean frame time of the last second.
  final double fps;
  final double frameMs;

  bool get running => effectId != null && !loading && !paused && issue == null;

  HtmlEffectStatus copyWith({
    String? effectId,
    bool? loading,
    bool? paused,
    HtmlEffectIssue? issue,
    List<String>? issueArgs,
    String? error,
    double? fps,
    double? frameMs,
  }) => HtmlEffectStatus(
    effectId: effectId ?? this.effectId,
    loading: loading ?? this.loading,
    paused: paused ?? this.paused,
    issue: issue ?? this.issue,
    issueArgs: issueArgs ?? this.issueArgs,
    error: error ?? this.error,
    fps: fps ?? this.fps,
    frameMs: frameMs ?? this.frameMs,
  );
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
        if (gen == _generation) {
          state = HtmlEffectStatus(
            effectId: effectId,
            issue: HtmlEffectIssue.unsupported,
            issueArgs: [for (final i in effect.compatibility.issues) i.name],
          );
        }
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
      final raw = cfg.effectValues[effectId] ?? const <String, Object?>{};
      if (!identical(raw, _valuesSent)) {
        for (final e in raw.entries) {
          runtime.setProperty(e.key, e.value);
        }
        _valuesSent = raw;
      }
      // The render worker samples the LEDs once it knows the LED positions;
      // the app samples from the frame itself when it does not (see the
      // `colors == null` fallback below).
      if (!identical(_sampleConfig, cfg)) {
        runtime.setSamplePoints(canvasSamplePoints(cfg));
        _sampleConfig = cfg;
      }
      final sample = ref.read(monitoringProvider).latest;
      if (sample != null && !identical(sample, _sensorsSent)) {
        runtime.setSensors(sample.values);
        _sensorsSent = sample;
      }

      final (frame, colors) = await runtime.renderSampled(
        DateTime.now().difference(_started).inMicroseconds / 1000,
      );
      // The effect may have been switched while awaiting the frame.
      if (!ref.mounted || gen != _generation || !identical(runtime, _runtime)) {
        return;
      }
      if (ref.read(lightingProvider).effectId != effectId) return;
      ref
          .read(engineProvider)
          .send(
            SetHtmlEffectFrame(
              effectId,
              colors ?? sampleEffectFrame(cfg, frame),
            ),
          );
      _liveFrame?.value = frame;
      if (!_thumbnailSaved) {
        _thumbnailSaved = true;
        unawaited(_saveThumbnail(runtime));
      }
      _countFrame(sw.elapsed);
    } on Object catch (e) {
      // The effect may have been switched off while this frame was running.
      if (ref.mounted &&
          gen == _generation &&
          identical(runtime, _runtime) &&
          ref.read(lightingProvider).effectId == effectId) {
        _fail('$e');
      }
    } finally {
      if (gen == _generation) _busy = false;
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
    _timer?.cancel();
    _timer = null;
    _runtime?.dispose();
    _runtime = null;
    _liveFrame?.value = null;
    state = state.copyWith(
      paused: true,
      issue: HtmlEffectIssue.paused,
      issueArgs: ['$ms'],
      loading: false,
    );
  }

  void _fail(String detail) {
    _timer?.cancel();
    _timer = null;
    _runtime?.dispose();
    _runtime = null;
    _liveFrame?.value = null;
    state = HtmlEffectStatus(
      effectId: _effectId,
      issue: HtmlEffectIssue.loadFailed,
      error: detail,
    );
  }

  void _stop() {
    _generation++;
    _timer?.cancel();
    _timer = null;
    _runtime?.dispose();
    _runtime = null;
    _liveFrame?.value = null;
    _slug = null;
    _effectId = null;
    _valuesSent = null;
    _busy = false;
  }
}

final htmlEffectRunnerProvider =
    NotifierProvider<HtmlEffectRunner, HtmlEffectStatus>(HtmlEffectRunner.new);
