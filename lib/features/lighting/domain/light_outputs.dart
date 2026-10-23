// Lighting module domain (pure Dart): port to the physical light outputs.

import 'dart:async';

import 'light_device.dart';
import 'alv2_hardware_config.dart';
import 'gpu_hardware_config.dart';
import 'board_zone_config.dart';
import 'rgb.dart';

/// Everything the lighting engine needs from the hardware, in domain terms.
/// The protocol details (mode bytes, packet order, SMBus guards) belong to the
/// adapter built on the devices module.
///
/// The ITE, RAM and GPU writes are blocking I/O; implementations run them off
/// the engine isolate, so every write is a `Future`. Writes of one device are
/// applied in call order.
///
/// Every `bool` means "the device accepted the write"; `false` marks the
/// device as unavailable (absent, no permission, or blocked by a guard). The
/// implementations never throw for a missing device.
abstract interface class LightOutputs {
  // ── Fans (AL V2 hub, groups 0–3; group 0 is empty) ──────────────────────

  /// Startup sequence: motherboard ARGB sync off, merge order `0,1,2,3` and
  /// the fan quantity of every group ([quantity] has 4 values).
  Future<bool> initFans(List<int> quantity);

  /// Resends the fan quantity of the 4 groups.
  Future<bool> setFanQuantity(List<int> quantity);

  /// Streams canvas/fixed frames to the groups in [frames] (hub group ->
  /// fan LEDs, 20 per fan) in a single hub frame. Completes when the hub
  /// has written everything.
  Future<bool> sendFanFrames(Map<int, List<Rgb>> frames);

  /// Hardware mode of [group] (1–3).
  Future<bool> setFanHardware(int group, Alv2HardwareConfig config);

  /// Whether [mode] (a base name such as `Runway`) has a merge variant.
  bool supportsFanMerge(String mode);

  /// Merge across all groups. Only valid if [supportsFanMerge].
  Future<bool> setFanMerge(String mode, Alv2HardwareConfig config);

  /// Order the merge crosses the groups in ([order]: group at each of the 4
  /// positions, see `LightingConfig.alv2MergeOrder`).
  Future<bool> setFanMergeOrder(List<int> order);

  /// Turns the ports of [group] (0–3) off.
  Future<bool> turnFanGroupOff(int group);

  /// Turns every hub port off.
  Future<bool> turnAllFansOff();

  /// Pings [group] (1–3). With [merge] active it uses the merge ping; the
  /// caller reapplies the merge afterwards.
  Future<bool> identifyFanGroup(int group, {bool merge = false});

  // ── Motherboard and case strip (ITE) ────────────────────────────────────

  /// (Re)initializes the controller. Required again after [turnBoardOff].
  Future<bool> initBoard();

  /// D_LED1 case strip, 47 LEDs.
  Future<bool> sendChassis(List<Rgb> leds);

  /// Static colors of the board zones, in `boardZoneIds` order.
  Future<bool> sendBoardColors(List<Rgb> zones);

  /// Hardware effects of several board zones at once (keys are `0x20`/`0x22`/
  /// `0x23`): one batch, a single apply (the firmware needs pauses).
  Future<bool> setBoardZones(Map<int, BoardZoneConfig> zones);

  /// Black on every zone and on the case strip. Priority: frames not yet
  /// written are dropped so the off does not wait behind them.
  Future<bool> turnBoardOff();

  // ── Memory (Kingston Fury, slot 0/1 = ram1/ram2) ────────────────────────

  /// 12 LEDs of a stick.
  Future<bool> sendRam(int slot, List<Rgb> leds);

  /// Black on every usable stick. Priority, like [turnBoardOff].
  Future<bool> turnRamOff();

  // ── GPU (Gigabyte RX 9060 XT) ───────────────────────────────────────────

  /// Reads firmware and SSID. Every effect is refused until the SSID check
  /// succeeds (0x2429), so a wrong board never receives a 0x12.
  Future<bool> initGpu();

  /// Fixed color (`Static`) with the global brightness level (0–10).
  Future<bool> sendGpuColor(Rgb color, {int brightness = 10});

  /// Hardware/firmware effect of the GPU.
  Future<bool> setGpuHardware(GpuHardwareConfig config);

  /// Effect 0 (off). Priority, like [turnBoardOff].
  Future<bool> turnGpuOff();

  // ── Common ──────────────────────────────────────────────────────────────

  /// Why [id] cannot be used, when the driver knows (safety guard); `null`
  /// if there is no specific reason.
  String? blockedReason(LightDeviceId id);

  /// Forgets what the drivers think the hardware holds (their caches), so the
  /// next writes are complete. Called when the devices may have lost their
  /// state, for example after a resume.
  void invalidate();

  /// Releases what the module owns (ITE, SMBus, GPU I²C). The AL V2 hub
  /// belongs to the monitoring module and is not closed here.
  FutureOr<void> close();
}
