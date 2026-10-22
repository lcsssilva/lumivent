import '../domain/frame_composer.dart';
import '../domain/hardware_timing.dart';
import '../domain/light_device.dart';
import '../domain/lighting_config.dart';
import '../domain/rgb.dart';
import 'lighting_messages.dart';

/// Owns what the engine composes frames from: the current effect's canvas
/// pixels and the composition clock (including the firmware-Breathing phase
/// lock with the fans).
class LightingFrameCompositor {
  LightingFrameCompositor({required this.leadOf});

  final FrameComposer _composer = FrameComposer();

  /// How far ahead of "now" a family must be composed (send time EMA).
  final double Function(OutputFamily) leadOf;

  /// Colors sampled from the current HTML effect (UI isolate), and the effect
  /// they belong to. Frames from another effect are stale and dropped.
  Map<LightDeviceId, List<Rgb>>? _pixels;
  String? _pixelsEffect;

  /// Engine time (seconds) at which the firmware `Breathing` started, or
  /// `null` when the fans are not running it. The canvas devices are composed
  /// against this instant so they breathe in phase (see
  /// [breathingEffectTime]).
  double? _breathingSince;

  /// Accepts a sampled frame of [effectId]; [pixelsFor] drops them as soon as
  /// the engine shows another effect.
  void accept(String effectId, Map<LightDeviceId, List<Rgb>> pixels) {
    _pixelsEffect = effectId;
    _pixels = pixels;
  }

  /// Invalidates the pixels entirely (effect switch, off, re-init).
  void invalidate() {
    _pixels = null;
    _pixelsEffect = null;
  }

  /// Adds the breathing anchor [since] as the time the firmware started the
  /// mode; invalidates with [clearBreathing] when nothing breathes anymore.
  void anchorBreathing(double since) => _breathingSince = since;
  void clearBreathing() => _breathingSince = null;

  /// Whether any enabled fan group runs the firmware `Breathing` for the
  /// current effect: only then the canvas devices follow the firmware clock.
  bool usesFirmwareBreathing(LightingConfig c) {
    if (c.effectId != 'breathing') return false;
    for (final id in LightDeviceId.values.where((d) => d.isFan)) {
      final d = c.device(id);
      if (d.enabled &&
          d.mode == LightMode.hardware &&
          c.alv2Hardware[id.hubGroup!].mode == 'Breathing') {
        return true;
      }
    }
    return false;
  }

  /// Sampled colors usable for the effect [config] shows.
  Map<LightDeviceId, List<Rgb>>? pixelsFor(LightingConfig config) =>
      _pixelsEffect == config.effectId ? _pixels : null;

  /// [showAt] (effect seconds) as the canvas devices must evaluate it so a
  /// firmware `Breathing` keeps its phase with the fans.
  double showTime(LightingConfig config, double showAt) {
    final since = _breathingSince;
    final values = config.effectValuesFor();
    if (since == null || values == null || config.effectId != 'breathing') {
      return showAt;
    }
    return breathingEffectTime(
      showAt: showAt,
      anchor: since,
      period: alv2BreathingPeriod(values.number('speed')),
    );
  }

  /// Colors of [only] at the instant [family] will show them, for the send
  /// starting at [seconds] (engine seconds).
  Map<LightDeviceId, List<Rgb>> composeFrame(
    LightingConfig config, {
    required Set<LightDeviceId> only,
    required double seconds,
    required OutputFamily family,
  }) {
    final lead = leadOf(family);
    return _composer.compose(
      config,
      seconds,
      only: only,
      pixels: pixelsFor(config),
      timeFor: (_) => showTime(config, seconds + lead),
    );
  }

  /// Colors of one device for the instant [family] will show them, when the
  /// send starts at [seconds].
  List<Rgb>? composeDevice(
    LightingConfig config, {
    required LightDeviceId id,
    required double seconds,
    required OutputFamily family,
  }) {
    final lead = leadOf(family);
    return _composer.compose(
      config,
      seconds,
      only: {id},
      pixels: pixelsFor(config),
      timeFor: (_) => showTime(config, seconds + lead),
    )[id];
  }

  /// The GPU Canvas average as it must be evaluated for it to show at
  /// [seconds] (engine seconds including the family lead already added).
  Rgb gpuAverage(LightingConfig config, {required double seconds}) =>
      _composer.averageCanvasColor(
        config,
        LightDeviceId.gpu,
        showTime(config, seconds),
        pixels: pixelsFor(config),
      );
}
