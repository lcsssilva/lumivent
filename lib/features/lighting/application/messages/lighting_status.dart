import '../../../../core/engine/engine_event.dart';
import '../../domain/light_device.dart';
import '../status/light_output_state.dart';
import '../status/light_output_status.dart';
import '../status/loop_stats.dart';

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
