import '../../domain/light_device.dart';
import '../../domain/outputs/light_outputs.dart';
import '../../domain/config/lighting_config.dart';
import '../../domain/rgb.dart';
import '../hardware/device_health_monitor.dart';
import '../status/light_output_state.dart';
import 'lighting_frame_compositor.dart';
import 'lighting_frame_deduplicator.dart';
import 'lighting_latency_model.dart';
import '../status/lighting_status_reporter.dart';
import '../lighting_trace.dart';
import 'output_lane.dart';

/// Sends one frame of an output family for the lighting engine: composes the
/// due devices for their latency, skips what the hardware already shows,
/// sends, then records the measured time and the sent colors. A failed send
/// takes the family down through [onFamilyDown].
class LightingFrameSender {
  LightingFrameSender({
    required this.compositor,
    required this.deduplicator,
    required this.latency,
    required this.health,
    required this.status,
    required this.now,
    required this.retryEvery,
    required this.gpuFrameGap,
    required this.config,
    required this.seconds,
    required this.lanes,
    required this.alive,
    required this.onFamilyDown,
  });

  static const _fanIds = {
    LightDeviceId.alv2Group1,
    LightDeviceId.alv2Group2,
    LightDeviceId.alv2Group3,
  };

  final LightingFrameCompositor compositor;
  final LightingFrameDeduplicator deduplicator;
  final LightingLatencyModel latency;
  final DeviceHealthMonitor health;
  final LightingStatusReporter status;
  final DateTime Function() now;

  /// Wait before a RAM stick that failed is tried again.
  final Duration retryEvery;

  /// Minimum interval between GPU writes (part of the GPU lead).
  final Duration gpuFrameGap;

  /// The config the engine acts on.
  final LightingConfig Function() config;

  /// Effect time of [at], in seconds since the engine started.
  final double Function(DateTime at) seconds;
  final Map<OutputFamily, OutputLane> Function() lanes;

  /// Whether a reply for a frame sent under an epoch still matters.
  final bool Function(int epoch) alive;
  final void Function(OutputFamily family) onFamilyDown;

  /// Sends the due frame of [family]; `true` when something was sent.
  Future<bool> send(
    OutputFamily family,
    LightOutputs out,
    DateTime at,
    int epoch,
  ) => switch (family) {
    OutputFamily.fans => _fans(out, at, epoch),
    OutputFamily.ite => _ite(out, epoch),
    OutputFamily.ram => _ram(out, epoch),
    OutputFamily.gpu => _gpu(out, at, epoch),
  };

  /// Composes and sends the due fan groups. A frame dropped by a priority
  /// turn-off is not a driver failure.
  Future<bool> _fans(LightOutputs out, DateTime at, int epoch) async {
    final frame = compositor.composeFrame(
      config(),
      only: _fanIds,
      seconds: seconds(at),
      family: OutputFamily.fans,
    );
    final fans = <int, List<Rgb>>{};
    for (final MapEntry(key: id, value: leds) in frame.entries) {
      if (leds.isNotEmpty && deduplicator.shouldSendColors(id, leds, at)) {
        fans[id.hubGroup!] = leds;
      }
    }
    if (fans.isEmpty) return false;
    final lane = lanes()[OutputFamily.fans]!;
    final ok = await out.sendFanFrames(fans);
    if (!alive(epoch)) return true;
    if (ok) {
      final took = now().difference(at);
      latency.observe(OutputFamily.fans, took);
      lane
        ..record(took)
        ..countFrame();
      for (final e in fans.entries) {
        deduplicator.recordColors(
          LightDeviceId.forHubGroup(e.key)!,
          e.value,
          at,
        );
      }
    } else {
      onFamilyDown(OutputFamily.fans);
    }
    return true;
  }

  /// Chassis then board colors, each composed right before its own send.
  Future<bool> _ite(LightOutputs out, int epoch) async {
    var sent = false;
    final lane = lanes()[OutputFamily.ite]!;
    for (final id in const [LightDeviceId.chassis, LightDeviceId.motherboard]) {
      final at = now();
      final leds = compositor.composeDevice(
        config(),
        id: id,
        seconds: seconds(at),
        family: OutputFamily.ite,
      );
      if (leds == null || !deduplicator.shouldSendColors(id, leds, at)) {
        continue;
      }
      sent = true;
      final ok = await (id == LightDeviceId.chassis
          ? out.sendChassis(leds)
          : out.sendBoardColors(leds));
      if (!alive(epoch)) return true;
      if (!ok) {
        onFamilyDown(OutputFamily.ite);
        return true;
      }
      final took = now().difference(at);
      latency.observe(OutputFamily.ite, took);
      lane.record(took);
      if (lightingTrace && id == LightDeviceId.chassis) {
        traceLighting(
          '${seconds(at).toStringAsFixed(3)} s chassis '
          '${leds.first.toHex()} took ${took.inMilliseconds} ms',
        );
      }
      deduplicator.recordColors(id, leds, at);
    }
    if (sent) lane.countFrame();
    return sent;
  }

  /// Both Fury sticks in sequence (one frame in flight for the family).
  Future<bool> _ram(LightOutputs out, int epoch) async {
    var sent = false, wrote = false;
    final lane = lanes()[OutputFamily.ram]!;
    for (final id in const [LightDeviceId.ram1, LightDeviceId.ram2]) {
      final at = now();
      final retryAt = health.ramRetryAt(id);
      if (retryAt != null && at.isBefore(retryAt)) continue;
      final leds = compositor.composeDevice(
        config(),
        id: id,
        seconds: seconds(at),
        family: OutputFamily.ram,
      );
      if (leds == null || !deduplicator.shouldSendColors(id, leds, at)) {
        continue;
      }
      sent = true;
      final ok = await out.sendRam(id == LightDeviceId.ram1 ? 0 : 1, leds);
      if (!alive(epoch)) return true;
      if (ok) {
        final took = now().difference(at);
        latency.observe(OutputFamily.ram, took);
        lane.record(took);
        wrote = true;
        deduplicator.recordColors(id, leds, at);
        if (health.recordRamSuccess(id)) status.emitStatus();
      } else {
        deduplicator.forget(id);
        health.recordRamFailure(id, at.add(retryEvery));
        status.emitStatus();
      }
    }
    if (wrote) lane.countFrame();
    return sent;
  }

  /// Sends the GPU's single color (Canvas average or Fixed) or turns it off
  /// when disabled/brightness 0. Canvas colors are resent only when they
  /// change (or on the safety resend), so a static image costs one write.
  Future<bool> _gpu(LightOutputs out, DateTime at, int epoch) async {
    final cfg = config();
    final d = cfg.device(LightDeviceId.gpu);
    if (d.mode == LightMode.hardware) return false;
    final off = !d.enabled || cfg.brightness <= 0;
    final brightness = off ? 0 : _gpuBrightness(cfg.brightness);
    final color = off
        ? Rgb.black
        : (d.mode == LightMode.fixed
                  ? d.fixedColor
                  : compositor.gpuAverage(
                      cfg,
                      seconds:
                          seconds(at) +
                          latency.leadSeconds(OutputFamily.gpu, gpuFrameGap),
                    ))
              .scaled(_gpuColorScale(cfg.brightness));
    if (!deduplicator.shouldSendGpu(color, brightness, at)) return false;

    final lane = lanes()[OutputFamily.gpu]!;
    final ok = off
        ? await out.turnGpuOff()
        : await out.sendGpuColor(color, brightness: brightness);
    if (!alive(epoch)) return true;
    if (!ok) {
      onFamilyDown(OutputFamily.gpu);
      return true;
    }
    final took = now().difference(at);
    latency.observe(OutputFamily.gpu, took);
    lane
      ..record(took)
      ..countFrame();
    deduplicator.recordGpu(color, brightness, at);
    return true;
  }

  /// Global brightness (0–1) as the controller's 0–10 byte. Byte 0 is never
  /// sent here (off is handled by the caller); below 10% the byte stays at 1
  /// and [_gpuColorScale] dims the color for the rest.
  static int _gpuBrightness(double brightness) =>
      (brightness * 10).round().clamp(1, 10);

  /// Color factor below the controller's lowest step (byte 1 ≈ 10%), so 1–9%
  /// is not shown at 10% while every other device follows the slider.
  static double _gpuColorScale(double brightness) =>
      brightness >= 0.1 ? 1.0 : brightness * 10;
}
