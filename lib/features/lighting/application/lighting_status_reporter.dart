import '../../../core/engine/engine_host.dart';
import '../domain/light_device.dart';
import '../domain/light_outputs.dart';
import 'device_health_monitor.dart';
import 'lighting_messages.dart';
import 'lighting_trace.dart';
import 'output_scheduler.dart';

/// Emits the lighting status: per-device output state, measured FPS and
/// per-family loop stats.
///
/// FPS/counters are only emitted when something changed, at most once per
/// second (unless [emitStatus] is forced); the trace line goes to stderr once
/// per stats window.
class LightingStatusReporter {
  LightingStatusReporter({
    required this.emit,
    required this.now,
    required this.outputs,
    required this.health,
    required this.lanes,
    required this.leadOf,
  });

  final void Function(EngineEvent event) emit;
  final DateTime Function() now;
  final LightOutputs? Function() outputs;
  final DeviceHealthMonitor Function() health;
  final Map<OutputFamily, OutputLane> Function() lanes;

  /// How far ahead a family is drawn (for the trace line).
  final double Function(OutputFamily family) leadOf;

  // FPS and status.
  int _frames = 0;
  DateTime _fpsWindowStart = DateTime.fromMillisecondsSinceEpoch(0);
  double _measuredFps = 0;
  LightingStatus? _lastStatus;
  Map<OutputFamily, LoopStats> _loops = const {};
  DateTime _lastFpsEmit = DateTime.fromMillisecondsSinceEpoch(0);

  /// A new tick window starts ([OutputScheduler.onStarted]).
  void loopStarted(DateTime at) {
    _frames = 0;
    _fpsWindowStart = at;
  }

  /// The loop went inactive.
  void loopStopped() {
    _measuredFps = 0;
    emitStatus(force: true);
  }

  void tickStarted() => _frames++;

  /// The stats window ended: rebuild the loop stats and emit if changed.
  void updateFps(DateTime at) {
    final elapsed = at.difference(_fpsWindowStart);
    if (elapsed < const Duration(seconds: 1)) return;
    final familyLanes = lanes();
    _loops = {
      for (final MapEntry(key: f, value: lane) in familyLanes.entries)
        f: LoopStats(
          fps: (lane.frames * 10000000 / elapsed.inMicroseconds).round() / 10,
          sendMs: lane.frames == 0
              ? null
              : (lane.sendUs / lane.frames / 100).round() / 10,
        ),
    };
    if (lightingTrace) {
      String stats(OutputFamily f) {
        final lane = familyLanes[f]!;
        return '${f.name} ${lane.frames} frames avg '
            '${_loops[f]!.sendMs ?? '-'} ms';
      }

      traceLighting(
        'ticks $_frames, ${stats(OutputFamily.fans)}, '
        'fan lead ${(leadOf(OutputFamily.fans) * 1000).toStringAsFixed(0)} ms, '
        '${stats(OutputFamily.ite)}, ${stats(OutputFamily.ram)}, '
        '${stats(OutputFamily.gpu)}',
      );
    }
    for (final lane in familyLanes.values) {
      lane.resetStats();
    }
    _measuredFps = (_frames * 1000000 / elapsed.inMicroseconds).roundToDouble();
    _frames = 0;
    _fpsWindowStart = at;
    emitStatus();
  }

  /// Emits only when a device status changed or the FPS changed; the FPS goes
  /// out at most once per second ([force] skips that limit).
  void emitStatus({bool force = false}) {
    final at = now();
    final devices = _deviceStatus();
    final last = _lastStatus;
    final fpsDue =
        force || at.difference(_lastFpsEmit) >= const Duration(seconds: 1);
    final fps = fpsDue ? _measuredFps : (last?.fps ?? 0);
    final loops = fpsDue ? _loops : (last?.loops ?? const {});
    if (last != null &&
        fps == last.fps &&
        sameLoops(loops, last.loops) &&
        sameStatus(last.devices, devices)) {
      return;
    }
    if (fps != (last?.fps ?? 0) || !sameLoops(loops, last?.loops ?? const {})) {
      _lastFpsEmit = at;
    }
    emit(_lastStatus = LightingStatus(devices, fps: fps, loops: loops));
  }

  Map<LightDeviceId, LightOutputStatus> _deviceStatus() {
    final out = outputs();
    final monitor = health();
    LightOutputStatus status(LightDeviceId id) {
      if (!id.isSupported) {
        return const LightOutputStatus(
          LightOutputState.unsupported,
          issue: LightOutputIssue.unsupported,
        );
      }
      if (out == null) {
        return const LightOutputStatus(LightOutputState.unavailable);
      }
      final (up, reason) = switch (id) {
        _ when id.isFan => (monitor.fansReady, LightOutputIssue.hub),
        LightDeviceId.chassis ||
        LightDeviceId.motherboard => (monitor.boardReady, LightOutputIssue.ite),
        LightDeviceId.gpu => (monitor.gpuReady, LightOutputIssue.gpu),
        _ => (!monitor.ramDown.contains(id), LightOutputIssue.ram),
      };
      if (up) return const LightOutputStatus(LightOutputState.ok);
      final blocked = out.blockedReason(id);
      if (id == LightDeviceId.gpu) {
        // The GPU guard has its own explanation (missing adapter, permission,
        // failed identification read, SSID mismatch); do not call it a
        // generic "safety block".
        return LightOutputStatus(
          LightOutputState.unavailable,
          issue: LightOutputIssue.gpu,
          args: blocked == null ? const [] : [blocked],
        );
      }
      return LightOutputStatus(
        LightOutputState.unavailable,
        issue: blocked == null ? reason : LightOutputIssue.blocked,
        args: blocked == null ? const [] : [blocked],
      );
    }

    return {for (final id in LightDeviceId.values) id: status(id)};
  }
}

bool sameLoops(
  Map<OutputFamily, LoopStats> a,
  Map<OutputFamily, LoopStats> b,
) => a.length == b.length && a.entries.every((e) => b[e.key] == e.value);

bool sameStatus(
  Map<LightDeviceId, LightOutputStatus> a,
  Map<LightDeviceId, LightOutputStatus> b,
) {
  if (a.length != b.length) return false;
  for (final e in a.entries) {
    if (b[e.key] != e.value) return false;
  }
  return true;
}
