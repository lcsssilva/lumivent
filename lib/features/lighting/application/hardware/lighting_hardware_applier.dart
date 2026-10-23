import 'package:flutter/foundation.dart' show listEquals;

import '../../domain/hardware_mode/hardware_equivalent.dart';
import '../../domain/light_device.dart';
import '../../domain/native_effects/native_effects.dart';
import '../../domain/outputs/light_outputs.dart';
import '../../domain/config/lighting_config.dart';
import '../../domain/hardware_mode/alv2_hardware_config.dart';
import '../../domain/hardware_mode/gpu_hardware_config.dart';
import '../../domain/config/board_zone_config.dart';
import '../../domain/rgb.dart';
import 'lighting_hardware_state.dart';
import '../status/light_output_state.dart';

/// What a device slot holds, as recorded in the [LightingHardwareState]
/// signatures. `frame` slots follow the canvas frames, so nothing is written
/// for them.
enum _SlotMode { frame, off, mode, merged }

/// Sends the hardware modes (fan modes, merge, board zones, GPU) comparing the
/// requested config with what the hardware holds. Idempotent; a `false` from a
/// driver drops the family so the module's retry redoes it.
///
/// The wiring is inverted on purpose: the module owns the retry timers, status,
/// stop state and the engine clock, and the [LightingHardwareApplier] only
/// writes in call order.
class LightingHardwareApplier {
  LightingHardwareApplier({
    required this.state,
    required this.onFamilyDown,
    required this.onBreathingStarted,
    required this.trace,
    required this.stopped,
  });

  /// Signatures of everything the hardware holds.
  final LightingHardwareState state;

  /// The mode write failed: the family drops and the retry redoes it.
  final void Function(OutputFamily family) onFamilyDown;

  /// A firmware `Breathing` was written: the frame clock anchors to it.
  final void Function() onBreathingStarted;

  /// Detailed timing trace line (stderr, given `LUMIVENT_LIGHTING_TRACE`).
  final void Function(String what) trace;

  /// The engine stopped; mid-sequence writes must bail out.
  final bool Function() stopped;

  /// Compare-and-send of the whole fan subtree: quantity, merge, group 0 and
  /// the per-group mode. Returns whether an effect was written.
  Future<bool> reconcileFans({
    required LightingConfig config,
    required LightingConfig user,
    required LightOutputs out,
  }) async {
    final state = this.state;
    var sent = false;
    final qty = LightingHardwareState.quantityOf(config);
    final appliedQty = state.appliedQuantity;
    if (appliedQty == null || !listEquals(appliedQty, qty)) {
      // The service resends every port after a quantity change (AL-V2 §4).
      final ok = await out.setFanQuantity(qty);
      if (stopped()) return sent;
      if (!ok) {
        onFamilyDown(OutputFamily.fans);
        return sent;
      }
      state
        ..appliedQuantity = qty
        ..forgetFans();
    }

    final merged = _mergeWanted(config, user, out);
    final appliedOrder = state.appliedMergeOrder;
    if (merged &&
        (appliedOrder == null ||
            !listEquals(appliedOrder, config.alv2MergeOrder))) {
      final ok = await out.setFanMergeOrder(config.alv2MergeOrder);
      if (stopped()) return sent;
      if (!ok) {
        onFamilyDown(OutputFamily.fans);
        return sent;
      }
      state.appliedMergeOrder = config.alv2MergeOrder;
      // The effect is sent again so it starts on the new path.
      state.forget(LightingHardwareState.mergeKey);
    }
    final mergeSig = merged
        ? (_SlotMode.merged, config.alv2MergeMode, config.alv2Hardware[0])
        : null;
    if (state.changed(LightingHardwareState.mergeKey, mergeSig)) {
      // The merge config lives in the unused group-0 slot of the hardware list.
      if (merged) {
        final ok = await out.setFanMerge(
          config.alv2MergeMode,
          config.alv2Hardware[0],
        );
        if (stopped()) return sent;
        if (!ok) {
          onFamilyDown(OutputFamily.fans);
          return sent;
        }
        sent = true;
        trace(
          'merge ${config.alv2MergeMode} '
          'order ${config.alv2MergeOrder}',
        );
      } else {
        trace('merge off');
      }
      state.apply(LightingHardwareState.mergeKey, mergeSig);
    }
    state.fanMerged = merged;

    // Hub group 0 is empty and always off, except port 0 inside a merge.
    final g0 = merged ? _SlotMode.merged : _SlotMode.off;
    if (state.changed(LightingHardwareState.group0Key, g0)) {
      if (!merged) {
        final ok = await out.turnFanGroupOff(0);
        if (stopped()) return sent;
        if (!ok) {
          onFamilyDown(OutputFamily.fans);
          return sent;
        }
        trace('fan group 0 off');
      }
      state.apply(LightingHardwareState.group0Key, g0);
    }

    for (final id in LightDeviceId.values.where((d) => d.isFan)) {
      final d = config.device(id);
      final g = id.hubGroup!;
      final (_SlotMode, Alv2HardwareConfig?) sig = merged
          ? (_SlotMode.merged, null)
          : d.mode != LightMode.hardware
          ? (_SlotMode.frame, null)
          : !d.enabled
          ? (_SlotMode.off, null)
          : (_SlotMode.mode, config.alv2Hardware[g]);
      if (!state.changed(id, sig)) continue;
      state.forgetFrameColors(id);
      final ok = switch (sig.$1) {
        _SlotMode.off => await out.turnFanGroupOff(g),
        _SlotMode.mode => await out.setFanHardware(g, sig.$2!),
        _SlotMode.frame || _SlotMode.merged => true,
      };
      if (stopped()) return sent;
      if (!ok) {
        onFamilyDown(OutputFamily.fans);
        return sent;
      }
      if (sig.$1 != _SlotMode.mode) trace('fan group $g ${sig.$1.name}');
      if (sig.$1 == _SlotMode.mode) {
        sent = true;
        final m = sig.$2!;
        trace(
          'fan group $g ${m.mode} speed ${m.speed} brightness '
          '${m.brightness} left ${m.directionLeft} colors '
          '${m.colors.take(2).map((c) => c.toHex()).join(',')}',
        );
        // A Breathing mode starts its own clock now: the canvas follows it.
        if (sig.$2!.mode == breathingFirmwareMode &&
            config.effectId == breathingEffectId) {
          onBreathingStarted();
        }
      }
      state.apply(id, sig);
    }
    return sent;
  }

  /// The merge is needed when the toggle is on, the mode has a merge variant,
  /// at least one fan group is enabled, and every enabled group is in
  /// hardware mode. Otherwise the groups follow their own modes. Disabled
  /// groups inside an active merge cannot be turned off separately (the merge
  /// covers all ports) and receive no canvas frames.
  bool _mergeWanted(
    LightingConfig config,
    LightingConfig user,
    LightOutputs out,
  ) {
    if (!config.alv2Merge || !out.supportsFanMerge(config.alv2MergeMode)) {
      return false;
    }
    // Judged on the user's modes: groups that only run a derived firmware
    // mode do not turn the merge on.
    final enabled = [
      for (final id in LightDeviceId.values)
        if (id.isFan && user.device(id).enabled) user.device(id),
    ];
    return enabled.isNotEmpty &&
        enabled.every((d) => d.mode == LightMode.hardware);
  }

  /// Board zones whose hardware effect changed go out in a single batch.
  /// Returns whether a zone effect was written.
  Future<bool> reconcileBoard({
    required LightingConfig config,
    required LightOutputs out,
  }) async {
    final state = this.state;
    final d = config.device(LightDeviceId.motherboard);
    final batch = <int, BoardZoneConfig>{};
    final sigs = <int, Object?>{};
    for (final z in boardZoneIds) {
      final (_SlotMode, BoardZoneConfig?) sig = d.mode != LightMode.hardware
          ? (_SlotMode.frame, null)
          : !d.enabled
          ? (_SlotMode.off, null)
          : (_SlotMode.mode, config.boardZones[z]);
      if (!state.changed(z, sig)) continue;
      state.forgetFrameColors(LightDeviceId.motherboard);
      switch (sig.$1) {
        case _SlotMode.off:
          batch[z] = const BoardZoneConfig(
            mode: BoardEffectMode.static,
            color: Rgb.black,
          );
          sigs[z] = sig;
        case _SlotMode.mode:
          batch[z] = sig.$2!;
          sigs[z] = sig;
        case _SlotMode.frame || _SlotMode.merged:
          state.apply(z, sig);
      }
    }
    if (batch.isEmpty) return false;
    final ok = await out.setBoardZones(batch);
    if (stopped()) return false;
    if (!ok) {
      onFamilyDown(OutputFamily.ite);
      return false;
    }
    for (final entry in sigs.entries) {
      state.apply(entry.key, entry.value);
    }
    return true;
  }

  /// The GPU's firmware effect. Returns whether a hardware effect was written
  /// (the module must not consider the old frame applied for it).
  Future<bool> reconcileGpu({
    required LightingConfig config,
    required LightOutputs out,
  }) async {
    final state = this.state;
    final d = config.device(LightDeviceId.gpu);
    final (_SlotMode, GpuHardwareConfig?) sig = d.mode != LightMode.hardware
        ? (_SlotMode.frame, null)
        : !d.enabled
        ? (_SlotMode.off, null)
        : (_SlotMode.mode, config.gpuHardware);
    if (!state.changed(LightDeviceId.gpu, sig)) return false;
    // Frame mode must resend its color on the next tick; hardware/off must not
    // be considered already applied by the old frame.
    state.forgetGpuFrameColors();
    var ok = true;
    var hardware = false;
    switch (sig.$1) {
      case _SlotMode.off:
        ok = await out.turnGpuOff();
      case _SlotMode.mode:
        ok = await out.setGpuHardware(sig.$2!);
        hardware = true;
      case _SlotMode.frame || _SlotMode.merged:
        break;
    }
    if (stopped()) return false;
    if (!ok) {
      onFamilyDown(OutputFamily.gpu);
      return false;
    }
    state.apply(LightDeviceId.gpu, sig);
    return hardware;
  }
}
