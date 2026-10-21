import '../../../core/engine/engine_host.dart';
import '../domain/light_device.dart';
import '../domain/lighting_config.dart';
import '../domain/rgb.dart';

/// Turns all ARGB off/on (top bar, tray). The engine also receives the full
/// config through [SetLightingConfig]; this one stays for the shortcut paths.
class SetArgbOff extends EngineCommand {
  const SetArgbOff(this.off);
  final bool off;
}

/// New lighting configuration. The engine applies only what changed:
/// hardware modes are resent when their settings change, canvas/fixed devices
/// follow on the next frame.
class SetLightingConfig extends EngineCommand {
  const SetLightingConfig(this.config);
  final LightingConfig config;
}

/// LEDs sampled from an HTML effect frame (plan §5.5). Sent by the UI
/// isolate at the effects FPS; [effectId] must be the current global effect,
/// otherwise the frame is stale and ignored by the engine.
class SetHtmlEffectFrame extends EngineCommand {
  const SetHtmlEffectFrame(this.effectId, this.pixels);
  final String effectId;
  final Map<LightDeviceId, List<Rgb>> pixels;
}

/// "Identify" button of a fan group (AL V2 ping, AL-V2 §4). [group] is the
/// hub group (1–3).
class IdentifyFanGroup extends EngineCommand {
  const IdentifyFanGroup(this.group);
  final int group;
}

class ArgbStateChanged extends EngineEvent {
  const ArgbStateChanged(this.off);
  final bool off;
}

enum LightOutputState {
  /// Last write accepted by the device.
  ok,

  /// Device absent, no permission, or blocked by a guard.
  unavailable,

  /// No driver yet (kept for the UI; all current devices have one).
  unsupported,
}

class LightOutputStatus {
  const LightOutputStatus(this.state, {this.detail});
  final LightOutputState state;

  /// Reason shown in the UI when [state] is not [LightOutputState.ok]
  /// (Portuguese, user-facing).
  final String? detail;

  @override
  bool operator ==(Object other) =>
      other is LightOutputStatus &&
      other.state == state &&
      other.detail == detail;

  @override
  int get hashCode => Object.hash(state, detail);
}

/// Output families with their own send latency and frame lane (see
/// `LightingEngineModule.latencyOf`).
enum OutputFamily {
  /// AL V2 hub: asynchronous canvas frame, ports arrive over the whole send.
  fans,

  /// ITE controller (case strip and motherboard zones): HID in the I/O worker.
  ite,

  /// Kingston Fury sticks: SMBus in the I/O worker.
  ram,

  /// Gigabyte GPU: I²C in the I/O worker, one effect every 120 ms at most.
  gpu,
}

/// Frames one family sent in the last second and their mean send time.
class LoopStats {
  const LoopStats({required this.fps, required this.sendMs});
  final double fps;

  /// `null` when no frame went out (nothing changed, or the family is off).
  final double? sendMs;

  @override
  bool operator ==(Object other) =>
      other is LoopStats && other.fps == fps && other.sendMs == sendMs;

  @override
  int get hashCode => Object.hash(fps, sendMs);

  @override
  String toString() => 'LoopStats($fps fps, $sendMs ms)';
}

/// Per-device output status. Emitted by the engine only when it changes.
class LightingStatus extends EngineEvent {
  const LightingStatus(
    this.devices, {
    required this.fps,
    this.loops = const {},
  });
  final Map<LightDeviceId, LightOutputStatus> devices;

  /// Frames per second actually reached by the LED loop (last second).
  final double fps;

  /// Per-family frames and send time over the last second (diagnostics).
  final Map<OutputFamily, LoopStats> loops;
}
