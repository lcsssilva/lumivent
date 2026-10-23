import 'dart:async';

import 'package:lumivent/features/lighting/domain/light_device.dart';
import 'package:lumivent/features/lighting/domain/light_outputs.dart';
import 'package:lumivent/features/lighting/domain/lighting_config.dart';
import 'package:lumivent/features/lighting/domain/board_zone_config.dart';
import 'package:lumivent/features/lighting/domain/rgb.dart';

/// Records every call; each family can be made to fail.
class FakeOutputs implements LightOutputs {
  final calls = <String>[];
  bool fansOk = true, boardOk = true, ramOk = true;
  bool fanHwOk = true, mergeOk = true;

  /// The GPU starts unavailable, like a machine whose OEM bus is absent or
  /// whose identity read fails; GPU tests set [gpuOk] to true.
  bool gpuOk = false;
  bool throwFanFrames = false;
  bool closed = false;
  int invalidations = 0;

  /// Colors received by the frame sends, in order (latency tests).
  final fanLog = <Map<int, List<Rgb>>>[];
  final chassisLog = <List<Rgb>>[];
  final ramLog = <List<Rgb>>[];
  final fanHwLog = <(int, Alv2HardwareConfig)>[];
  final gpuLog = <(Rgb, int)>[];
  final gpuHwLog = <GpuHardwareConfig>[];

  /// Simulated send time of each family, and a hook run when a send starts.
  Duration fanDelay = Duration.zero,
      chassisDelay = Duration.zero,
      ramDelay = Duration.zero,
      gpuDelay = Duration.zero;
  void Function()? onChassisSend, onRamSend, onFanSend;
  void Function(int group, Alv2HardwareConfig config)? onFanHw;

  /// While set, `sendRam` / `sendChassis` do not finish.
  Completer<bool>? holdRam, holdChassis;

  /// Order of every call that reached the worker side (priority tests).
  int maxRamInFlight = 0, maxChassisInFlight = 0;
  int _ramInFlight = 0, _chassisInFlight = 0;

  /// While set, `sendFanFrames` does not finish (frame overlap test).
  Completer<bool>? holdFans;

  /// While set, `setFanQuantity` does not finish (lane gate test).
  Completer<bool>? holdQty;

  /// While set, `initFans` does not finish (stop-during-startup test).
  Completer<bool>? holdInitFans;
  bool throwOnClose = false;
  String? blocked;

  int count(String prefix) => calls.where((c) => c.startsWith(prefix)).length;
  void clear() => calls.clear();

  @override
  Future<bool> initFans(List<int> quantity) async {
    calls.add('initFans:${quantity.join(',')}');
    final hold = holdInitFans;
    if (hold != null) return hold.future;
    return fansOk;
  }

  @override
  Future<bool> setFanQuantity(List<int> quantity) async {
    calls.add('qty:${quantity.join(',')}');
    final hold = holdQty;
    if (hold != null) return hold.future;
    return fansOk;
  }

  @override
  Future<bool> sendFanFrames(Map<int, List<Rgb>> frames) async {
    calls.add('fanFrames:${frames.keys.join(',')}');
    fanLog.add(frames);
    onFanSend?.call();
    if (fanDelay > Duration.zero) await Future<void>.delayed(fanDelay);
    if (throwFanFrames) throw StateError('fan frame failed');
    final hold = holdFans;
    if (hold != null) return hold.future;
    return fansOk;
  }

  @override
  Future<bool> setFanHardware(int group, Alv2HardwareConfig config) async {
    calls.add('fanHw:$group:${config.mode}:${config.speed}');
    fanHwLog.add((group, config));
    onFanHw?.call(group, config);
    return fanHwOk;
  }

  @override
  bool supportsFanMerge(String mode) => const {'Runway', 'Wave'}.contains(mode);

  @override
  Future<bool> setFanMerge(String mode, Alv2HardwareConfig config) async {
    calls.add('merge:$mode');
    return mergeOk;
  }

  @override
  Future<bool> setFanMergeOrder(List<int> order) async {
    calls.add('mergeOrder:${order.join(',')}');
    return fansOk;
  }

  @override
  Future<bool> turnFanGroupOff(int group) async {
    calls.add('fanOff:$group');
    return fansOk;
  }

  @override
  Future<bool> turnAllFansOff() async {
    calls.add('allFansOff');
    return fansOk;
  }

  @override
  Future<bool> identifyFanGroup(int group, {bool merge = false}) async {
    calls.add('identify:$group:$merge');
    return fansOk;
  }

  @override
  Future<bool> initBoard() async {
    calls.add('initBoard');
    return boardOk;
  }

  @override
  Future<bool> sendChassis(List<Rgb> leds) async {
    calls.add('chassis');
    chassisLog.add(leds);
    onChassisSend?.call();
    if (++_chassisInFlight > maxChassisInFlight) {
      maxChassisInFlight = _chassisInFlight;
    }
    try {
      if (chassisDelay > Duration.zero) {
        await Future<void>.delayed(chassisDelay);
      }
      final hold = holdChassis;
      if (hold != null) return await hold.future;
      return boardOk;
    } finally {
      _chassisInFlight--;
    }
  }

  @override
  Future<bool> sendBoardColors(List<Rgb> zones) async {
    calls.add('boardColors');
    return boardOk;
  }

  @override
  Future<bool> setBoardZones(Map<int, BoardZoneConfig> zones) async {
    for (final MapEntry(key: zone, value: config) in zones.entries) {
      calls.add('zone:$zone:${config.mode.name}:${config.color.toHex()}');
    }
    return boardOk;
  }

  @override
  void invalidate() => invalidations++;

  @override
  Future<bool> turnBoardOff() async {
    calls.add('boardOff');
    return boardOk;
  }

  @override
  Future<bool> sendRam(int slot, List<Rgb> leds) async {
    calls.add('ram:$slot');
    ramLog.add(leds);
    onRamSend?.call();
    if (++_ramInFlight > maxRamInFlight) maxRamInFlight = _ramInFlight;
    try {
      if (ramDelay > Duration.zero) await Future<void>.delayed(ramDelay);
      final hold = holdRam;
      if (hold != null) return await hold.future;
      return ramOk;
    } finally {
      _ramInFlight--;
    }
  }

  @override
  Future<bool> turnRamOff() async {
    calls.add('ramOff');
    return ramOk;
  }

  @override
  Future<bool> initGpu() async {
    calls.add('initGpu');
    return gpuOk;
  }

  @override
  Future<bool> sendGpuColor(Rgb color, {int brightness = 10}) async {
    calls.add('gpuStatic:${color.toHex()}:$brightness');
    gpuLog.add((color, brightness));
    if (gpuDelay > Duration.zero) await Future<void>.delayed(gpuDelay);
    return gpuOk;
  }

  @override
  Future<bool> setGpuHardware(GpuHardwareConfig config) async {
    calls.add('gpuHw:${config.effect.name}');
    gpuHwLog.add(config);
    return gpuOk;
  }

  @override
  Future<bool> turnGpuOff() async {
    calls.add('gpuOff');
    return gpuOk;
  }

  @override
  String? blockedReason(LightDeviceId id) => switch (id) {
    LightDeviceId.gpu => gpuOk ? null : 'GPU de teste indisponível',
    _ when id.isRam => blocked,
    _ => null,
  };

  @override
  void close() {
    closed = true;
    if (throwOnClose) throw StateError('close failed');
  }
}
