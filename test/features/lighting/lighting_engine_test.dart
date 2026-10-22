import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/core/engine/engine_host.dart';
import 'package:lumivent/features/lighting/application/lighting_engine_commands.dart';
import 'package:lumivent/features/lighting/application/lighting_engine_module.dart';
import 'package:lumivent/features/lighting/application/lighting_messages.dart';
import 'package:lumivent/features/lighting/domain/frame_composer.dart';
import 'package:lumivent/features/lighting/domain/hardware_equivalents.dart';
import 'package:lumivent/features/lighting/domain/hardware_timing.dart';
import 'package:lumivent/features/lighting/domain/light_device.dart';
import 'package:lumivent/features/lighting/domain/light_outputs.dart';
import 'package:lumivent/features/lighting/domain/led_layout.dart';
import 'package:lumivent/features/lighting/domain/lighting_config.dart';
import 'package:lumivent/features/lighting/domain/power_events.dart';
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

class FakePowerWatcher implements PowerWatcher {
  Future<void> Function()? beforeSleep, beforeShutdown;
  void Function()? afterResume;
  bool started = false, stopped = false;
  bool failOnStart = false;

  @override
  Future<void> start({
    required Future<void> Function() beforeSleep,
    required void Function() afterResume,
    required Future<void> Function() beforeShutdown,
  }) async {
    if (failOnStart) throw StateError('no bus');
    started = true;
    this.beforeSleep = beforeSleep;
    this.afterResume = afterResume;
    this.beforeShutdown = beforeShutdown;
  }

  @override
  Future<void> stop() async => stopped = true;
}

LightingConfig withModes(
  LightingConfig base,
  Map<LightDeviceId, LightMode> modes,
) => modes.entries.fold(
  base,
  (c, e) => c.withDevice(e.key, c.device(e.key).copyWith(mode: e.value)),
);

final supported = [
  for (final id in LightDeviceId.values)
    if (id.isSupported) id,
];

/// Every device in a fixed color: a frame is sent once and then stays.
LightingConfig fixedConfig([LightingConfig? base]) => withModes(
  base ?? LightingConfig(),
  {for (final id in supported) id: LightMode.fixed},
);

/// Every device that accepts hardware in hardware mode.
final hardwareModes = {
  for (final id in supported)
    if (id.accepts(LightMode.hardware)) id: LightMode.hardware,
};

/// Fan frame gap of the lane tests: they exercise fast canvas streaming,
/// so they do not run at the real [alv2SafeStreamGap].
const legacyFanFrameGap = Duration(milliseconds: 40);

/// Module + fakes + virtual clock driven by `tester.pump`.
class Rig {
  Rig(
    this.tester,
    LightingConfig config, {
    int fps = 30,
    bool startNow = true,
    bool autoHardware = false,
    Duration fanFrameGap = legacyFanFrameGap,
    this.outputs,
  }) : config = config.copyWith(autoHardware: autoHardware),
       _auto = autoHardware {
    outputs ??= FakeOutputs();
    module = LightingEngineModule(
      openOutputs: () => outputs!,
      openWatcher: () => watcher,
      initial: this.config,
      fps: fps,
      fanFrameGap: fanFrameGap,
      now: () => origin.add(elapsed),
    );
    if (startNow) start();
  }

  final WidgetTester tester;
  final LightingConfig config;

  /// Legacy tests exercise canvas streaming, so the rig switches the automatic
  /// hardware mode off in every config unless asked otherwise.
  final bool _auto;
  FakeOutputs? outputs;
  final watcher = FakePowerWatcher();
  final events = <EngineEvent>[];
  final origin = DateTime(2026, 10, 19);
  Duration elapsed = Duration.zero;
  late final LightingEngineModule module;

  FakeOutputs get out => outputs!;

  Iterable<LightingStatus> get statuses => events.whereType<LightingStatus>();
  LightingStatus get lastStatus => statuses.last;
  List<bool> get argbEvents =>
      events.whereType<ArgbStateChanged>().map((e) => e.off).toList();

  void start() => module.start(events.add);

  /// Advances the virtual clock in 10 ms steps, running timers and futures.
  Future<void> advance(Duration d) async {
    const step = Duration(milliseconds: 10);
    for (var left = d; left > Duration.zero; left -= step) {
      final s = left < step ? left : step;
      elapsed += s;
      await tester.pump(s);
    }
    await tester.pump();
  }

  Future<void> settle() => advance(const Duration(milliseconds: 20));

  /// Runs a watcher callback to completion.
  Future<void> fire(Future<void> Function()? callback) async {
    final f = callback!();
    await settle();
    await f;
  }

  void send(EngineCommand c) => module.handle(
    c is SetLightingConfig && !_auto
        ? SetLightingConfig(c.config.copyWith(autoHardware: false))
        : c,
  );
}

void main() {
  const second = Duration(seconds: 1);

  testWidgets('frames reach the port at the configured fps', (tester) async {
    final rig = Rig(tester, LightingConfig());
    await rig.settle();
    rig.out.clear();
    await rig.advance(second);
    final chassis = rig.out.count('chassis');
    expect(chassis, inInclusiveRange(28, 31));
    // AL V2 canvas frames are spaced by fanFrameGap (40 ms): at most 25 fps.
    expect(rig.out.count('fanFrames'), inInclusiveRange(8, 26));

    rig.send(const SetLightingFps(60));
    rig.out.clear();
    await rig.advance(second);
    // The 10 ms virtual clock quantizes the 16.7 ms frame gap (20/30 ms).
    expect(rig.out.count('chassis'), inInclusiveRange(38, 62));
    rig.module.stop();
  });

  testWidgets('nothing is resent while the color does not change', (
    tester,
  ) async {
    final rig = Rig(tester, fixedConfig());
    await rig.advance(const Duration(milliseconds: 500));
    expect(rig.out.count('chassis'), 1);
    expect(rig.out.count('boardColors'), 1);
    expect(rig.out.count('ram:0'), 1);
    expect(rig.out.count('ram:1'), 1);
    expect(rig.out.count('fanFrames'), 1);

    await rig.advance(const Duration(seconds: 3));
    expect(rig.out.count('chassis'), 1);
    expect(rig.out.count('fanFrames'), 1);

    // Safety resend after ~5 s.
    await rig.advance(const Duration(seconds: 3));
    expect(rig.out.count('chassis'), 2);
    expect(rig.out.count('fanFrames'), 2);
    rig.module.stop();
  });

  testWidgets('a color change is sent on the next frame', (tester) async {
    final rig = Rig(tester, fixedConfig());
    await rig.advance(const Duration(milliseconds: 500));
    rig.send(
      SetLightingConfig(
        fixedConfig().withDevice(
          LightDeviceId.chassis,
          fixedConfig()
              .device(LightDeviceId.chassis)
              .copyWith(fixedColor: Rgb.black),
        ),
      ),
    );
    rig.out.clear();
    await rig.advance(const Duration(milliseconds: 200));
    expect(rig.out.count('chassis'), 1);
    expect(rig.out.count('boardColors'), 0);
    expect(rig.out.count('fanFrames'), 0);
    rig.module.stop();
  });

  testWidgets('canvas -> hardware -> canvas switches the fan group', (
    tester,
  ) async {
    final canvas = LightingConfig();
    final rig = Rig(tester, canvas);
    await rig.advance(const Duration(milliseconds: 300));
    expect(rig.out.count('fanHw'), 0);

    final hardware = withModes(canvas, {
      LightDeviceId.alv2Group1: LightMode.hardware,
    });
    rig.send(SetLightingConfig(hardware));
    await rig.advance(const Duration(milliseconds: 100));
    expect(rig.out.calls.where((c) => c.startsWith('fanHw')), [
      'fanHw:1:StaticColor:2',
    ]);

    // From now on frames carry only groups 2 and 3.
    rig.out.clear();
    await rig.advance(const Duration(milliseconds: 300));
    final frames = rig.out.calls.where((c) => c.startsWith('fanFrames'));
    expect(frames, isNotEmpty);
    expect(frames.every((c) => c == 'fanFrames:2,3'), isTrue);

    rig.send(SetLightingConfig(canvas));
    rig.out.clear();
    await rig.advance(const Duration(milliseconds: 200));
    expect(rig.out.calls.where((c) => c.startsWith('fanFrames:1')), isNotEmpty);
    expect(rig.out.count('fanHw'), 0);
    rig.module.stop();
  });

  testWidgets('hardware is resent only when its own config changes', (
    tester,
  ) async {
    final base = withModes(LightingConfig(), hardwareModes);
    final rig = Rig(tester, base);
    await rig.advance(const Duration(milliseconds: 200));
    expect(rig.out.count('fanHw'), 3);
    expect(rig.out.count('zone'), 3);
    // Hardware only: no frame loop at all.
    expect(rig.out.count('fanFrames'), 0);

    rig.out.clear();
    rig.send(SetLightingConfig(base.copyWith(brightness: 0.3)));
    rig.send(SetLightingConfig(base.copyWith(offOnSleep: false)));
    await rig.advance(const Duration(milliseconds: 200));
    expect(
      rig.out.calls.where((c) => c.startsWith('fanHw') || c.startsWith('zone')),
      isEmpty,
    );

    final hw = [...base.alv2Hardware];
    hw[2] = hw[2].copyWith(speed: 4, mode: 'Rainbow');
    rig.send(SetLightingConfig(base.copyWith(alv2Hardware: hw)));
    await rig.advance(const Duration(milliseconds: 200));
    expect(rig.out.calls.where((c) => c.startsWith('fanHw')), [
      'fanHw:2:Rainbow:4',
    ]);

    rig.out.clear();
    final zones = {...base.boardZones};
    zones[0x22] = zones[0x22]!.copyWith(
      mode: BoardEffectMode.wave,
      color: const Rgb(0, 0, 255),
    );
    rig.send(
      SetLightingConfig(base.copyWith(alv2Hardware: hw, boardZones: zones)),
    );
    await rig.advance(const Duration(milliseconds: 200));
    expect(rig.out.calls.where((c) => c.startsWith('zone')), [
      'zone:34:wave:#0000FF',
    ]);
    rig.module.stop();
  });

  testWidgets('a disabled hardware device is turned off', (tester) async {
    var base = withModes(LightingConfig(), hardwareModes);
    for (final id in [LightDeviceId.alv2Group2, LightDeviceId.motherboard]) {
      base = base.withDevice(id, base.device(id).copyWith(enabled: false));
    }
    final rig = Rig(tester, base);
    await rig.advance(const Duration(milliseconds: 200));
    expect(rig.out.calls, contains('fanOff:2'));
    expect(rig.out.calls, isNot(contains('fanOff:1')));
    expect(rig.out.calls.where((c) => c.startsWith('fanHw')), [
      'fanHw:1:StaticColor:2',
      'fanHw:3:StaticColor:2',
    ]);
    expect(rig.out.count('zone'), 3);
    expect(
      rig.out.calls
          .where((c) => c.startsWith('zone'))
          .every((c) => c.endsWith(':static:#000000')),
      isTrue,
    );
    rig.module.stop();
  });

  testWidgets('startup init: sync off, quantities, group 0 off', (
    tester,
  ) async {
    final rig = Rig(tester, LightingConfig(fanQuantity: [5, 2, 3, 4]));
    await rig.settle();
    expect(rig.out.calls.take(4), [
      'initFans:0,2,3,4',
      'initBoard',
      'initGpu',
      'fanOff:0',
    ]);
    expect(rig.watcher.started, isTrue);
    rig.module.stop();
  });

  testWidgets('merge is used only if every enabled group is in hardware', (
    tester,
  ) async {
    final fans = [
      LightDeviceId.alv2Group1,
      LightDeviceId.alv2Group2,
      LightDeviceId.alv2Group3,
    ];
    final allHw = withModes(LightingConfig(alv2Merge: true), {
      for (final id in fans) id: LightMode.hardware,
    });
    final rig = Rig(tester, allHw);
    await rig.advance(const Duration(milliseconds: 200));
    expect(rig.out.calls, contains('merge:Runway'));
    expect(rig.out.count('fanHw'), 0);
    expect(rig.out.calls, isNot(contains('fanOff:0')));

    // A group in canvas: merge is ignored and each group follows its mode.
    rig.out.clear();
    rig.send(
      SetLightingConfig(
        withModes(allHw, {LightDeviceId.alv2Group2: LightMode.canvas}),
      ),
    );
    await rig.advance(const Duration(milliseconds: 300));
    expect(rig.out.count('merge'), 0);
    expect(rig.out.calls, contains('fanOff:0'));
    expect(rig.out.calls.where((c) => c.startsWith('fanHw')), [
      'fanHw:1:StaticColor:2',
      'fanHw:3:StaticColor:2',
    ]);
    expect(rig.out.calls.where((c) => c.startsWith('fanFrames')), isNotEmpty);
    rig.module.stop();
  });

  testWidgets('merge order goes out before the merge, and only if changed', (
    tester,
  ) async {
    final hw = {
      LightDeviceId.alv2Group1: LightMode.hardware,
      LightDeviceId.alv2Group2: LightMode.hardware,
      LightDeviceId.alv2Group3: LightMode.hardware,
    };
    List<String> mergeCalls(Rig rig) =>
        rig.out.calls.where((c) => c.startsWith('merge')).toList();

    // The default order is what initFans leaves on the hub: not sent again.
    final plain = withModes(LightingConfig(alv2Merge: true), hw);
    final rig = Rig(tester, plain);
    await rig.advance(const Duration(milliseconds: 200));
    expect(mergeCalls(rig), ['merge:Runway']);

    // A custom order goes out first, and the effect is sent again after it.
    rig.out.clear();
    rig.send(
      SetLightingConfig(plain.copyWith(alv2MergeOrder: const [0, 1, 3, 2])),
    );
    await rig.advance(const Duration(milliseconds: 300));
    expect(mergeCalls(rig), ['mergeOrder:0,1,3,2', 'merge:Runway']);

    // Without merge the order is not touched.
    rig.out.clear();
    rig.send(
      SetLightingConfig(
        plain.copyWith(alv2Merge: false, alv2MergeOrder: const [0, 3, 2, 1]),
      ),
    );
    await rig.advance(const Duration(milliseconds: 300));
    expect(rig.out.count('mergeOrder'), 0);
    rig.module.stop();
  });

  testWidgets('merge ignored when the mode has no merge variant', (
    tester,
  ) async {
    final fans = withModes(
      LightingConfig(alv2Merge: true, alv2MergeMode: 'Rainbow'),
      {
        LightDeviceId.alv2Group1: LightMode.hardware,
        LightDeviceId.alv2Group2: LightMode.hardware,
        LightDeviceId.alv2Group3: LightMode.hardware,
      },
    );
    final rig = Rig(tester, fans);
    await rig.advance(const Duration(milliseconds: 200));
    expect(rig.out.count('merge'), 0);
    expect(rig.out.count('fanHw'), 3);
    rig.module.stop();
  });

  testWidgets('quantity is resent only when it changes', (tester) async {
    final rig = Rig(tester, fixedConfig());
    await rig.advance(const Duration(milliseconds: 300));
    expect(rig.out.count('qty'), 0);

    rig.send(SetLightingConfig(fixedConfig().copyWith(brightness: 0.5)));
    await rig.advance(const Duration(milliseconds: 100));
    expect(rig.out.count('qty'), 0);

    rig.send(
      SetLightingConfig(fixedConfig().copyWith(fanQuantity: [0, 3, 6, 3])),
    );
    await rig.advance(const Duration(milliseconds: 100));
    expect(rig.out.calls.where((c) => c.startsWith('qty')), ['qty:0,3,6,3']);

    // Group 0 quantity never reaches the hub.
    rig.send(
      SetLightingConfig(fixedConfig().copyWith(fanQuantity: [4, 3, 6, 3])),
    );
    await rig.advance(const Duration(milliseconds: 100));
    expect(rig.out.count('qty'), 1);
    rig.module.stop();
  });

  testWidgets('a hub write does not freeze the ITE/RAM/GPU lanes', (
    tester,
  ) async {
    final out = FakeOutputs();
    final rig = Rig(tester, LightingConfig(), outputs: out);
    await rig.settle();
    out.clear();
    // A config write to the hub runs as its own job and gates only the fans
    // lane: the writes of one family must not stop the families whose buses
    // and isolates it does not share.
    out.holdQty = Completer<bool>();
    rig.send(
      SetLightingConfig(LightingConfig().copyWith(fanQuantity: [0, 3, 6, 3])),
    );
    await rig.advance(const Duration(milliseconds: 300));
    expect(out.count('chassis'), greaterThan(1));
    expect(out.count('ram:0'), greaterThan(1));
    expect(out.count('fanFrames'), 0);

    // The fans lane resumes when its own write returns.
    out.holdQty!.complete(true);
    await rig.settle();
    expect(out.calls, contains('qty:0,3,6,3'));
    await rig.advance(const Duration(milliseconds: 300));
    expect(out.count('fanFrames'), greaterThan(0));
    rig.module.stop();
  });

  testWidgets('identify pings the group and reapplies the merge', (
    tester,
  ) async {
    final rig = Rig(tester, fixedConfig());
    await rig.advance(const Duration(milliseconds: 200));
    rig.send(const IdentifyFanGroup(2));
    await rig.advance(const Duration(milliseconds: 100));
    expect(rig.out.calls, contains('identify:2:false'));

    final merged = withModes(LightingConfig(alv2Merge: true), {
      LightDeviceId.alv2Group1: LightMode.hardware,
      LightDeviceId.alv2Group2: LightMode.hardware,
      LightDeviceId.alv2Group3: LightMode.hardware,
    });
    rig.send(SetLightingConfig(merged));
    await rig.advance(const Duration(milliseconds: 200));
    rig.out.clear();
    rig.send(const IdentifyFanGroup(3));
    await rig.advance(const Duration(milliseconds: 200));
    expect(
      rig.out.calls.where(
        (c) => c.startsWith('identify') || c.startsWith('merge'),
      ),
      ['identify:3:true', 'merge:Runway'],
    );
    // Out-of-range groups are ignored.
    rig.out.clear();
    rig.send(const IdentifyFanGroup(0));
    rig.send(const IdentifyFanGroup(9));
    await rig.advance(const Duration(milliseconds: 100));
    expect(rig.out.count('identify'), 0);
    rig.module.stop();
  });

  testWidgets('ARGB off turns everything off and the loop stops', (
    tester,
  ) async {
    final base = withModes(LightingConfig(), {
      LightDeviceId.alv2Group1: LightMode.hardware,
    });
    final rig = Rig(tester, base);
    await rig.advance(const Duration(milliseconds: 300));
    rig.out.clear();

    rig.send(const SetArgbOff(true));
    await rig.advance(const Duration(milliseconds: 300));
    expect(rig.out.calls, ['allFansOff', 'boardOff', 'ramOff', 'gpuOff']);
    expect(rig.argbEvents, [false, true]);

    // No frames while off.
    rig.out.clear();
    await rig.advance(const Duration(seconds: 2));
    expect(rig.out.calls, isEmpty);

    // Turning back on: driver init, hardware modes, and the loop come back.
    rig.send(const SetArgbOff(false));
    await rig.advance(const Duration(milliseconds: 500));
    expect(rig.out.calls.take(4), [
      'initFans:0,3,3,1',
      'initBoard',
      'initGpu',
      'fanOff:0',
    ]);
    expect(rig.out.calls, contains('fanHw:1:StaticColor:2'));
    expect(rig.out.count('chassis'), greaterThan(5));
    expect(rig.argbEvents, [false, true, false]);
    rig.module.stop();
  });

  testWidgets('config with argbOff behaves like SetArgbOff', (tester) async {
    final rig = Rig(tester, LightingConfig());
    await rig.advance(const Duration(milliseconds: 200));
    rig.out.clear();
    rig.send(SetLightingConfig(LightingConfig(argbOff: true)));
    await rig.advance(const Duration(milliseconds: 200));
    expect(rig.out.calls, ['allFansOff', 'boardOff', 'ramOff', 'gpuOff']);
    expect(rig.argbEvents, [false, true]);
    rig.module.stop();
  });

  testWidgets('starting with ARGB off turns off once and sends no frames', (
    tester,
  ) async {
    final rig = Rig(tester, LightingConfig(argbOff: true));
    await rig.advance(const Duration(seconds: 2));
    expect(rig.out.calls, ['allFansOff', 'boardOff', 'ramOff', 'gpuOff']);
    expect(rig.argbEvents, [true]);
    rig.module.stop();
  });

  testWidgets('sleep and resume with offOnSleep on', (tester) async {
    final rig = Rig(tester, LightingConfig());
    await rig.advance(const Duration(milliseconds: 300));
    rig.out.clear();

    await rig.fire(rig.watcher.beforeSleep);
    expect(rig.out.calls, ['allFansOff', 'boardOff', 'ramOff', 'gpuOff']);
    rig.out.clear();
    await rig.advance(const Duration(seconds: 1));
    expect(rig.out.calls, isEmpty);
    // The ARGB switch is not touched by sleep.
    expect(rig.argbEvents, [false]);

    rig.watcher.afterResume!();
    await rig.advance(const Duration(milliseconds: 300));
    expect(rig.out.calls.first, 'initFans:0,3,3,1');
    expect(rig.out.count('chassis'), greaterThan(3));
    rig.module.stop();
  });

  testWidgets('shutdown turns off and does not restore', (tester) async {
    final rig = Rig(tester, LightingConfig());
    await rig.advance(const Duration(milliseconds: 300));
    rig.out.clear();
    await rig.fire(rig.watcher.beforeShutdown);
    expect(rig.out.calls, ['allFansOff', 'boardOff', 'ramOff', 'gpuOff']);
    rig.out.clear();
    await rig.advance(const Duration(seconds: 1));
    expect(rig.out.calls, isEmpty);
    rig.module.stop();
  });

  testWidgets('sleep does nothing but resume re-inits with offOnSleep off', (
    tester,
  ) async {
    final rig = Rig(tester, LightingConfig(offOnSleep: false));
    await rig.advance(const Duration(milliseconds: 300));
    rig.out.clear();
    await rig.fire(rig.watcher.beforeSleep);
    await rig.fire(rig.watcher.beforeShutdown);
    expect(
      rig.out.calls.where(
        (c) => ['allFansOff', 'boardOff', 'ramOff', 'gpuOff'].contains(c),
      ),
      isEmpty,
    );
    rig.watcher.afterResume!();
    await rig.advance(const Duration(milliseconds: 300));
    // USB may have been reset: drivers re-init and frames are resent.
    expect(
      rig.out.calls.where(
        (c) => ['allFansOff', 'boardOff', 'ramOff', 'gpuOff'].contains(c),
      ),
      isEmpty,
    );
    expect(rig.out.calls.any((c) => c.startsWith('initFans')), isTrue);
    expect(rig.out.count('chassis'), greaterThan(3));
    rig.module.stop();
  });

  testWidgets('resume does not restore while ARGB is off', (tester) async {
    final rig = Rig(tester, LightingConfig());
    await rig.advance(const Duration(milliseconds: 300));
    rig.send(const SetArgbOff(true));
    await rig.advance(const Duration(milliseconds: 100));
    rig.out.clear();
    await rig.fire(rig.watcher.beforeSleep);
    rig.watcher.afterResume!();
    await rig.advance(const Duration(seconds: 1));
    expect(rig.out.calls, isEmpty);
    rig.module.stop();
  });

  testWidgets('a failing power watcher does not break the engine', (
    tester,
  ) async {
    final rig = Rig(tester, LightingConfig(), startNow: false);
    rig.watcher.failOnStart = true;
    rig.start();
    await rig.advance(const Duration(milliseconds: 300));
    expect(rig.out.count('chassis'), greaterThan(3));
    rig.module.stop();
  });

  testWidgets('GPU fixed color is Static with the global brightness', (
    tester,
  ) async {
    final base = LightingConfig();
    final cfg = base.withDevice(
      LightDeviceId.gpu,
      base
          .device(LightDeviceId.gpu)
          .copyWith(mode: LightMode.fixed, fixedColor: const Rgb(10, 20, 30)),
    );
    final out = FakeOutputs()..gpuOk = true;
    final rig = Rig(tester, cfg, outputs: out);
    await rig.advance(const Duration(milliseconds: 300));
    expect(out.gpuLog, [(const Rgb(10, 20, 30), 10)]);
    expect(out.gpuHwLog, isEmpty);

    // Global brightness maps to the controller's 0–10 byte.
    rig.send(SetLightingConfig(cfg.copyWith(brightness: 0.5)));
    await rig.advance(const Duration(milliseconds: 200));
    expect(out.gpuLog.last, (const Rgb(10, 20, 30), 5));

    // Below the controller's lowest step (byte 1 ≈ 10%) the color is dimmed
    // instead, so 5% is not shown at 10%.
    rig.send(SetLightingConfig(cfg.copyWith(brightness: 0.05)));
    await rig.advance(const Duration(milliseconds: 200));
    expect(out.gpuLog.last, (const Rgb(10, 20, 30).scaled(0.5), 1));

    // A new fixed color goes out; an unchanged one is not repeated.
    final next = cfg.withDevice(
      LightDeviceId.gpu,
      cfg
          .device(LightDeviceId.gpu)
          .copyWith(fixedColor: const Rgb(200, 100, 50)),
    );
    rig.send(SetLightingConfig(next.copyWith(brightness: 0.5)));
    await rig.advance(const Duration(milliseconds: 200));
    final count = out.gpuLog.length;
    expect(out.gpuLog.last, (const Rgb(200, 100, 50), 5));
    await rig.advance(const Duration(milliseconds: 500));
    expect(out.gpuLog.length, count);
    rig.module.stop();
  });

  testWidgets('GPU Canvas uses the average and only resends on change', (
    tester,
  ) async {
    final cfg = LightingConfig(effectId: 'html');
    final out = FakeOutputs()..gpuOk = true;
    final rig = Rig(tester, cfg, outputs: out);
    await rig.advance(const Duration(milliseconds: 300));
    out.gpuLog.clear();

    rig.send(
      const SetHtmlEffectFrame('html', {
        LightDeviceId.gpu: [Rgb(10, 20, 30), Rgb(20, 40, 60)],
      }),
    );
    await rig.advance(const Duration(milliseconds: 200));
    expect(out.gpuLog, [(const Rgb(15, 30, 45), 10)]);
    final count = out.gpuLog.length;
    await rig.advance(const Duration(milliseconds: 500));
    expect(out.gpuLog.length, count);

    rig.send(
      const SetHtmlEffectFrame('html', {
        LightDeviceId.gpu: [Rgb(1, 2, 3)],
      }),
    );
    await rig.advance(const Duration(milliseconds: 200));
    expect(out.gpuLog.last, (const Rgb(1, 2, 3), 10));
    expect(out.gpuLog.length, count + 1);
    rig.module.stop();
  });

  testWidgets('GPU disabled or brightness 0 turns the effect off once', (
    tester,
  ) async {
    final base = LightingConfig();
    for (final cfg in [
      base.withDevice(
        LightDeviceId.gpu,
        base.device(LightDeviceId.gpu).copyWith(enabled: false),
      ),
      base.copyWith(brightness: 0),
    ]) {
      final out = FakeOutputs()..gpuOk = true;
      final rig = Rig(tester, cfg, outputs: out);
      await rig.advance(const Duration(milliseconds: 400));
      expect(out.gpuLog, isEmpty);
      expect(out.calls.where((c) => c == 'gpuOff'), hasLength(1));
      rig.module.stop();
    }
  });

  testWidgets('GPU hardware mode sends the firmware effect, not frames', (
    tester,
  ) async {
    final base = LightingConfig();
    final cfg = base
        .withDevice(
          LightDeviceId.gpu,
          base.device(LightDeviceId.gpu).copyWith(mode: LightMode.hardware),
        )
        .copyWith(
          gpuHardware: const GpuHardwareConfig(
            effect: GpuEffect.pulse,
            speed: 4,
            brightness: 6,
            color: Rgb(1, 2, 3),
          ),
        );
    final out = FakeOutputs()..gpuOk = true;
    final rig = Rig(tester, cfg, outputs: out);
    await rig.advance(const Duration(milliseconds: 400));
    expect(out.gpuHwLog, hasLength(1));
    expect(out.gpuHwLog.single.effect, GpuEffect.pulse);
    expect(out.gpuHwLog.single.speed, 4);
    expect(out.gpuHwLog.single.brightness, 6);
    expect(out.gpuHwLog.single.color, const Rgb(1, 2, 3));
    expect(out.gpuLog, isEmpty);
    rig.module.stop();
  });

  testWidgets('GPU frame lane stays at or below 8 sends/s', (tester) async {
    final out = FakeOutputs()..gpuOk = true;
    final rig = Rig(tester, LightingConfig(), outputs: out);
    await rig.advance(const Duration(milliseconds: 300));
    out.gpuLog.clear();
    await rig.advance(const Duration(seconds: 1));
    expect(out.gpuLog.length, inInclusiveRange(5, 9));
    rig.module.stop();
  });

  testWidgets('GPU retries init and becomes available', (tester) async {
    final out = FakeOutputs();
    final rig = Rig(tester, LightingConfig(), outputs: out);
    await rig.advance(const Duration(milliseconds: 300));
    expect(
      rig.lastStatus.devices[LightDeviceId.gpu]!.state,
      LightOutputState.unavailable,
    );
    expect(out.gpuLog, isEmpty);

    out.gpuOk = true;
    await rig.advance(const Duration(seconds: 6));
    expect(
      rig.lastStatus.devices[LightDeviceId.gpu]!.state,
      LightOutputState.ok,
    );
    expect(out.gpuLog, isNotEmpty);
    rig.module.stop();
  });

  testWidgets('status: emitted only on change, fps at most once a second', (
    tester,
  ) async {
    final rig = Rig(tester, LightingConfig());
    await rig.advance(const Duration(seconds: 6));
    final first = rig.statuses.first;
    expect(
      first.devices[LightDeviceId.chassis]!.state,
      LightOutputState.unavailable,
    );
    expect(
      rig.statuses.any(
        (status) =>
            status.devices[LightDeviceId.chassis]!.state == LightOutputState.ok,
      ),
      isTrue,
    );
    final gpu = rig.statuses.last.devices[LightDeviceId.gpu]!;
    expect(gpu.state, LightOutputState.unavailable);
    expect(gpu.issue, LightOutputIssue.gpu);
    expect(gpu.args, ['GPU de teste indisponível']);
    // Only the fps and the loop stats change while everything is fine: at
    // most one per second.
    expect(rig.statuses.length, lessThanOrEqualTo(8));
    expect(rig.statuses.last.loops.keys, OutputFamily.values.toSet());
    expect(
      rig.statuses.last.loops[OutputFamily.ite]!.fps,
      inInclusiveRange(25, 31),
    );
    expect(
      rig.statuses
          .where((s) => s.fps > 0)
          .every((s) => s.fps >= 25 && s.fps <= 31),
      isTrue,
    );
    for (var i = 1; i < rig.statuses.length; i++) {
      final a = rig.statuses.elementAt(i - 1), b = rig.statuses.elementAt(i);
      // Compare values: default `toString` of the status objects would hide
      // a change of state/detail (both print as `Instance of ...`).
      final same =
          a.fps == b.fps &&
          mapEquals(a.loops, b.loops) &&
          mapEquals(a.devices, b.devices);
      expect(same, isFalse);
    }
    rig.module.stop();
  });

  testWidgets('status: device down with a reason, back after the retry', (
    tester,
  ) async {
    final rig = Rig(tester, fixedConfig(), startNow: false);
    rig.out
      ..gpuOk = true
      ..boardOk = false
      ..ramOk = false
      ..blocked = 'identity is not FURY';
    rig.start();
    await rig.advance(const Duration(seconds: 1));

    final s = rig.lastStatus;
    expect(
      s.devices[LightDeviceId.chassis]!.state,
      LightOutputState.unavailable,
    );
    expect(s.devices[LightDeviceId.motherboard]!.issue, LightOutputIssue.ite);
    expect(s.devices[LightDeviceId.ram1]!.issue, LightOutputIssue.blocked);
    expect(
      s.devices[LightDeviceId.ram1]!.args,
      contains('identity is not FURY'),
    );
    expect(s.devices[LightDeviceId.alv2Group1]!.state, LightOutputState.ok);

    // The device comes back: next retry re-inits it and resends the frame.
    rig.out
      ..boardOk = true
      ..ramOk = true
      ..blocked = null
      ..clear();
    await rig.advance(const Duration(seconds: 6));
    expect(rig.out.count('initBoard'), 1);
    expect(rig.out.count('chassis'), 1);
    expect(rig.out.count('ram:0'), greaterThanOrEqualTo(1));
    expect(
      rig.lastStatus.devices.values.where(
        (d) => d.state == LightOutputState.unavailable,
      ),
      isEmpty,
    );
    rig.module.stop();
  });

  testWidgets('GPU identification backs off and restarts on resume', (
    tester,
  ) async {
    final rig = Rig(tester, fixedConfig(), startNow: false);
    rig.out.gpuOk = false;
    rig.start();
    await rig.advance(const Duration(seconds: 1));
    expect(rig.out.count('initGpu'), 1);

    // Attempts at 0, 5, 15, 35 and 75 s (5 s doubling), not every 5 s.
    await rig.advance(const Duration(seconds: 79));
    expect(rig.out.count('initGpu'), 5);
    // The other families are up; the frame loop keeps running meanwhile.
    expect(rig.out.count('chassis'), greaterThan(10));

    // Resume may have fixed the bus: the next attempt is immediate.
    rig.out.clear();
    await rig.fire(rig.watcher.beforeSleep);
    rig.watcher.afterResume!();
    await rig.advance(const Duration(milliseconds: 300));
    expect(rig.out.count('initGpu'), greaterThanOrEqualTo(1));

    // Once the GPU answers, a later failure starts again from 5 s.
    rig.out.gpuOk = true;
    await rig.advance(const Duration(seconds: 6));
    expect(
      rig.lastStatus.devices[LightDeviceId.gpu]!.state,
      LightOutputState.ok,
    );
    rig.module.stop();
  });

  testWidgets('fan frames never overlap', (tester) async {
    final rig = Rig(tester, LightingConfig());
    await rig.settle();
    rig.out
      ..clear()
      ..holdFans = Completer<bool>();
    await rig.advance(const Duration(seconds: 1));
    expect(rig.out.count('fanFrames'), 1);

    rig.out.holdFans!.complete(true);
    rig.out.holdFans = null;
    await rig.advance(const Duration(milliseconds: 300));
    expect(rig.out.count('fanFrames'), greaterThan(1));
    rig.module.stop();
  });

  testWidgets('stop halts the loop and leaves the LEDs as they are', (
    tester,
  ) async {
    final rig = Rig(tester, LightingConfig());
    await rig.advance(const Duration(milliseconds: 300));
    rig.module.stop();
    rig.out.clear();
    await rig.advance(const Duration(seconds: 2));
    expect(rig.out.calls, isEmpty);
    expect(rig.watcher.stopped, isTrue);
    expect(rig.out.closed, isTrue);
  });

  testWidgets('unknown commands are not handled', (tester) async {
    final rig = Rig(tester, LightingConfig());
    expect(rig.module.handle(const ShutdownEngine()), isFalse);
    await rig.settle();
    rig.module.stop();
  });

  testWidgets('resume invalidates the driver caches and resends colors', (
    tester,
  ) async {
    final rig = Rig(tester, fixedConfig());
    await rig.advance(const Duration(milliseconds: 500));
    expect(rig.out.count('chassis'), 1);
    expect(rig.out.invalidations, 0);
    rig.out.clear();
    rig.watcher.afterResume!();
    await rig.advance(const Duration(milliseconds: 500));
    expect(rig.out.invalidations, 1);
    expect(rig.out.count('chassis'), 1);
    expect(rig.out.count('boardColors'), 1);
    expect(rig.out.count('ram:0'), 1);
    rig.module.stop();
  });

  testWidgets('stop during startup: nothing runs after the await', (
    tester,
  ) async {
    final rig = Rig(tester, LightingConfig(), startNow: false);
    rig.out.holdInitFans = Completer<bool>();
    rig.start();
    await rig.advance(const Duration(milliseconds: 100));
    rig.module.stop();
    rig.out.holdInitFans!.complete(true);
    await rig.advance(const Duration(milliseconds: 500));
    expect(rig.out.count('initBoard'), 0);
    expect(rig.out.count('chassis'), 0);
    expect(rig.out.closed, isTrue);
  });

  testWidgets('stop never throws, even if closing the outputs fails', (
    tester,
  ) async {
    final rig = Rig(tester, LightingConfig());
    await rig.advance(const Duration(milliseconds: 200));
    rig.out.throwOnClose = true;
    expect(rig.module.stop, returnsNormally);
  });

  testWidgets('RAM frames are limited to ~15 fps', (tester) async {
    final rig = Rig(tester, LightingConfig(), fps: 60);
    await rig.settle();
    rig.out.clear();
    await rig.advance(second);
    expect(rig.out.count('ram:0'), inInclusiveRange(10, 16));
    expect(rig.out.count('chassis'), greaterThan(35));
    rig.module.stop();
  });

  testWidgets('a down board is retried by its own timer, once per interval', (
    tester,
  ) async {
    final rig = Rig(
      tester,
      withModes(LightingConfig(), hardwareModes),
      startNow: false,
    );
    rig.out.boardOk = false;
    rig.start();
    await rig.advance(const Duration(seconds: 1));
    rig.out.boardOk = true;
    rig.out.clear();
    await rig.advance(const Duration(seconds: 6));
    expect(rig.out.count('initBoard'), 1);
    expect(
      rig.lastStatus.devices[LightDeviceId.motherboard]!.state,
      LightOutputState.ok,
    );
    rig.module.stop();
  });

  testWidgets('a failing hardware mode marks the fans down and retries', (
    tester,
  ) async {
    final rig = Rig(
      tester,
      withModes(LightingConfig(), {
        LightDeviceId.alv2Group1: LightMode.hardware,
      }),
      startNow: false,
    );
    rig.out.fanHwOk = false;
    rig.start();
    await rig.advance(const Duration(seconds: 1));
    expect(rig.out.count('fanHw'), 1);
    expect(
      rig.lastStatus.devices[LightDeviceId.alv2Group1]!.state,
      LightOutputState.unavailable,
    );

    rig.out.fanHwOk = true;
    rig.out.clear();
    await rig.advance(const Duration(seconds: 6));
    expect(rig.out.count('initFans'), 1);
    // The retry sends the mode and the scheduled resend sends it once more.
    expect(rig.out.count('fanHw'), 2);
    expect(
      rig.lastStatus.devices[LightDeviceId.alv2Group1]!.state,
      LightOutputState.ok,
    );
    rig.module.stop();
  });

  testWidgets('a failing quantity marks the fans down and retries', (
    tester,
  ) async {
    final rig = Rig(tester, fixedConfig());
    await rig.advance(const Duration(milliseconds: 300));
    rig.out
      ..clear()
      ..fansOk = false;
    rig.send(
      SetLightingConfig(fixedConfig().copyWith(fanQuantity: [0, 2, 3, 3])),
    );
    await rig.advance(const Duration(milliseconds: 300));
    expect(rig.out.count('qty'), 1);
    expect(
      rig.lastStatus.devices[LightDeviceId.alv2Group1]!.state,
      LightOutputState.unavailable,
    );

    rig.out
      ..fansOk = true
      ..clear();
    await rig.advance(const Duration(seconds: 6));
    expect(rig.out.count('initFans'), 1);
    expect(rig.out.count('chassis'), greaterThan(0));
    expect(
      rig.lastStatus.devices[LightDeviceId.alv2Group1]!.state,
      LightOutputState.ok,
    );
    rig.module.stop();
  });

  testWidgets('a failing merge marks the fans down and retries', (
    tester,
  ) async {
    final merged = withModes(LightingConfig(alv2Merge: true), {
      LightDeviceId.alv2Group1: LightMode.hardware,
      LightDeviceId.alv2Group2: LightMode.hardware,
      LightDeviceId.alv2Group3: LightMode.hardware,
    });
    final rig = Rig(tester, merged, startNow: false);
    rig.out.mergeOk = false;
    rig.start();
    await rig.advance(const Duration(seconds: 1));
    expect(rig.out.count('merge'), 1);
    expect(
      rig.lastStatus.devices[LightDeviceId.alv2Group2]!.state,
      LightOutputState.unavailable,
    );

    rig.out
      ..mergeOk = true
      ..clear();
    await rig.advance(const Duration(seconds: 6));
    // The retry sends the merge and the scheduled resend sends it once more.
    expect(rig.out.count('merge'), 2);
    expect(
      rig.lastStatus.devices[LightDeviceId.alv2Group2]!.state,
      LightOutputState.ok,
    );
    rig.module.stop();
  });

  testWidgets('a board that fails during a frame is retried and resent', (
    tester,
  ) async {
    final rig = Rig(tester, fixedConfig());
    await rig.advance(const Duration(milliseconds: 500));
    rig.out
      ..clear()
      ..boardOk = false;
    rig.send(
      SetLightingConfig(
        fixedConfig().withDevice(
          LightDeviceId.chassis,
          fixedConfig()
              .device(LightDeviceId.chassis)
              .copyWith(fixedColor: Rgb.black),
        ),
      ),
    );
    await rig.advance(const Duration(milliseconds: 300));
    expect(rig.out.count('chassis'), 1);
    expect(
      rig.lastStatus.devices[LightDeviceId.chassis]!.state,
      LightOutputState.unavailable,
    );

    rig.out
      ..boardOk = true
      ..clear();
    await rig.advance(const Duration(seconds: 6));
    expect(rig.out.count('initBoard'), 1);
    expect(rig.out.count('chassis'), greaterThan(0));
    expect(
      rig.lastStatus.devices[LightDeviceId.chassis]!.state,
      LightOutputState.ok,
    );
    rig.module.stop();
  });

  testWidgets('a throwing fan frame does not stop the loop', (tester) async {
    final rig = Rig(tester, LightingConfig(), startNow: false);
    rig.out.throwFanFrames = true;
    rig.start();
    await rig.advance(const Duration(seconds: 1));
    // Frames are attempted again after each failure (no overlap).
    expect(rig.out.count('fanFrames'), greaterThan(1));

    rig.out
      ..throwFanFrames = false
      ..clear();
    await rig.advance(const Duration(seconds: 1));
    expect(rig.out.count('fanFrames'), greaterThan(1));
    rig.module.stop();
  });

  group('parallel families', () {
    testWidgets('a slow RAM send delays neither the fans nor the ITE', (
      tester,
    ) async {
      final rig = Rig(tester, LightingConfig(), startNow: false);
      rig.out.ramDelay = const Duration(milliseconds: 800);
      rig.start();
      await rig.settle();
      rig.out.clear();
      await rig.advance(second);
      // The RAM lane is busy for most of the second ...
      expect(rig.out.count('ram:'), lessThanOrEqualTo(2));
      // ... while the chassis keeps its fps and the fans their gap.
      expect(rig.out.count('chassis'), inInclusiveRange(25, 31));
      expect(rig.out.count('fanFrames'), inInclusiveRange(8, 26));
      rig.module.stop();
      await rig.advance(second);
    });

    testWidgets('at most one frame is in flight per family', (tester) async {
      final rig = Rig(tester, LightingConfig(), fps: 60, startNow: false);
      rig.out
        ..chassisDelay = const Duration(milliseconds: 100)
        ..ramDelay = const Duration(milliseconds: 150);
      var fansInFlight = 0, maxFans = 0;
      rig.out
        ..fanDelay = const Duration(milliseconds: 90)
        ..onFanSend = () {
          maxFans = ++fansInFlight > maxFans ? fansInFlight : maxFans;
          Future<void>.delayed(const Duration(milliseconds: 90))
              .then((_) => fansInFlight--);
        };
      rig.start();
      await rig.advance(const Duration(seconds: 2));
      expect(rig.out.maxChassisInFlight, 1);
      expect(rig.out.maxRamInFlight, 1);
      expect(maxFans, 1);
      // Slow sends were chained, not stacked: ~10 chassis frames per second.
      expect(rig.out.count('chassis'), inInclusiveRange(10, 24));
      rig.module.stop();
      await rig.advance(second);
    });

    testWidgets('the off goes out at once and drops the pending frames', (
      tester,
    ) async {
      final rig = Rig(tester, LightingConfig());
      await rig.advance(const Duration(milliseconds: 300));
      // The RAM frame in flight does not finish (a long SMBus write).
      rig.out.holdRam = Completer<bool>();
      await rig.advance(const Duration(milliseconds: 300));
      final ramFrames = rig.out.count('ram:');
      final chassisBefore = rig.out.count('chassis');
      rig.out.clear();

      rig.send(const SetArgbOff(true));
      await rig.advance(const Duration(milliseconds: 100));
      // All three offs were requested without waiting for that frame ...
      expect(rig.out.count('allFansOff'), 1);
      expect(rig.out.count('boardOff'), 1);
      expect(rig.out.count('ramOff'), 1);
      // ... no new frame started after them ...
      expect(rig.out.count('ram:'), 0);
      expect(rig.out.count('chassis'), 0);
      expect(rig.out.count('fanFrames'), 0);
      expect(chassisBefore, greaterThan(0));
      expect(ramFrames, greaterThan(0));
      // ... and the stale frame finishing later changes nothing.
      rig.out.holdRam!.complete(true);
      await rig.advance(second);
      expect(rig.out.count('ram:'), 0);
      expect(
        rig.lastStatus.devices[LightDeviceId.ram1]!.state,
        LightOutputState.ok,
      );
      rig.module.stop();
    });

    testWidgets('stop closes the outputs (and so the worker) once', (
      tester,
    ) async {
      final rig = Rig(tester, LightingConfig());
      await rig.advance(const Duration(milliseconds: 300));
      rig.out.holdChassis = Completer<bool>();
      await rig.advance(const Duration(milliseconds: 100));
      rig.module.stop();
      expect(rig.out.closed, isTrue);
      rig.out.holdChassis!.complete(true);
      rig.out.clear();
      await rig.advance(second);
      expect(rig.out.calls, isEmpty);
    });
  });

  group('latency compensation', () {
    // The default effect (spectrum) changes color continuously with t.
    final config = LightingConfig();

    List<Rgb> at(LightDeviceId id, double t) => composeFrame(config, t)[id]!;

    testWidgets('fans get colors from the future, the chassis the present', (
      tester,
    ) async {
      final rig = Rig(tester, config, startNow: false);
      final m = rig.module;
      // (send instant in s, latency estimate used for that send in s)
      final chassis = <(double, double)>[], fans = <(double, double)>[];
      double secs() => rig.elapsed.inMicroseconds / 1e6;
      double lat(OutputFamily f) => m.latencyOf(f).inMicroseconds / 1e6;
      rig.out
        ..fanDelay = const Duration(milliseconds: 100)
        ..onFanSend = () {
          fans.add((secs(), lat(OutputFamily.fans)));
        }
        ..onChassisSend = () {
          chassis.add((secs(), lat(OutputFamily.ite)));
        };
      rig.start();
      await rig.advance(const Duration(seconds: 6));
      expect(m.latencyOf(OutputFamily.fans).inMilliseconds, closeTo(100, 12));
      expect(m.latencyOf(OutputFamily.ite).inMilliseconds, lessThan(2));

      // Chassis: present (plus its ~0 latency).
      final (chT, chLat) = chassis.last;
      expect(rig.out.chassisLog.last, at(LightDeviceId.chassis, chT + chLat));
      // Fans: the send time plus the firmware display delay (~250 ms ahead).
      final (fanT, fanLat) = fans.last;
      const display = LightingEngineModule.fanDisplayLatencyMs / 1000;
      expect(
        rig.out.fanLog.last[1],
        at(LightDeviceId.alv2Group1, fanT + fanLat + display),
      );
      expect(rig.out.fanLog.last[1], isNot(at(LightDeviceId.alv2Group1, fanT)));
      m.stop();
      await rig.advance(const Duration(milliseconds: 200));
    });

    testWidgets('RAM is composed latency ahead of the send instant', (
      tester,
    ) async {
      final rig = Rig(tester, config, startNow: false);
      final ram = <(double, double)>[];
      rig.out.onRamSend = () {
        ram.add((
          rig.elapsed.inMicroseconds / 1e6,
          rig.module.latencyOf(OutputFamily.ram).inMicroseconds / 1e6,
        ));
      };
      rig.out.ramDelay = const Duration(milliseconds: 40);
      rig.start();
      await rig.advance(const Duration(seconds: 6));
      expect(
        rig.module.latencyOf(OutputFamily.ram).inMilliseconds,
        closeTo(40, 6),
      );
      // The last two sends are ram1 then ram2 of one frame; look at ram1.
      final i = ram.length - 2;
      final (t, latency) = ram[i];
      expect(latency, greaterThan(0.03));
      expect(rig.out.ramLog[i], at(LightDeviceId.ram1, t + latency));
      rig.module.stop();
      await rig.advance(const Duration(milliseconds: 200));
    });

    testWidgets('the EMA converges to the measured duration and is clamped', (
      tester,
    ) async {
      final rig = Rig(tester, config, startNow: false);
      rig.out.ramDelay = const Duration(milliseconds: 60);
      rig.start();
      expect(rig.module.latencyOf(OutputFamily.ram).inMilliseconds, 10);
      await rig.advance(const Duration(seconds: 4));
      expect(
        rig.module.latencyOf(OutputFamily.ram).inMilliseconds,
        closeTo(60, 3),
      );

      // Far above the limit: stays at 150 ms.
      rig.out.ramDelay = const Duration(seconds: 2);
      await rig.advance(const Duration(seconds: 12));
      expect(
        rig.module.latencyOf(OutputFamily.ram),
        const Duration(milliseconds: 150),
      );
      // Instant sends pull it down but never below zero.
      rig.out.ramDelay = Duration.zero;
      await rig.advance(const Duration(seconds: 10));
      expect(
        rig.module.latencyOf(OutputFamily.ram).inMilliseconds,
        lessThan(3),
      );
      expect(rig.module.latencyOf(OutputFamily.ram).isNegative, isFalse);
      rig.module.stop();
    });

    testWidgets(
      'fan frames are chained without overlap, composed at send time',
      (tester) async {
        // Tick every 200 ms, but each send takes 60 ms: chaining sends far more.
        final rig = Rig(tester, config, fps: 5, startNow: false);
        var inFlight = 0, maxInFlight = 0;
        rig.out
          ..fanDelay = const Duration(milliseconds: 60)
          ..onFanSend = () {
            inFlight++;
            if (inFlight > maxInFlight) maxInFlight = inFlight;
            Future<void>.delayed(const Duration(milliseconds: 60))
                .then((_) => inFlight--);
          };
        rig.start();
        await rig.settle();
        rig.out.fanLog.clear();
        await rig.advance(const Duration(seconds: 1));
        final frames = rig.out.fanLog.length;
        expect(frames, inInclusiveRange(10, 17));
        expect(maxInFlight, 1);
        // Each frame was composed at its own send time (all distinct), not
        // reused from the 200 ms tick.
        expect({for (final f in rig.out.fanLog) f[1]!.first}.length, frames);
        rig.module.stop();
        await rig.advance(const Duration(milliseconds: 200));
      },
    );
  });

  group('automatic hardware', () {
    Iterable<String> hw(Rig rig) =>
        rig.out.calls.where((c) => c.startsWith('fanHw'));
    Iterable<String> zones(Rig rig) =>
        rig.out.calls.where((c) => c.startsWith('zone:'));

    testWidgets(
      'effect with equivalent: fans and board get hardware, no frames',
      (tester) async {
        final rig = Rig(tester, LightingConfig(), autoHardware: true);
        await rig.advance(const Duration(milliseconds: 500));
        expect(hw(rig), [
          'fanHw:1:Rainbow:1',
          'fanHw:2:Rainbow:1',
          'fanHw:3:Rainbow:1',
        ]);
        expect(zones(rig).length, 3);
        expect(zones(rig).every((c) => c.contains(':wave:')), isTrue);
        expect(rig.out.count('fanFrames'), 0);
        expect(rig.out.count('boardColors'), 0);
        // The case strip and RAM keep streaming.
        expect(rig.out.count('chassis'), greaterThan(0));
        expect(rig.out.count('ram:0'), greaterThan(0));
        rig.module.stop();
      },
    );

    testWidgets('effect without equivalent (HTML) streams the fans and '
        'back again', (tester) async {
      final rig = Rig(tester, LightingConfig(), autoHardware: true);
      await rig.advance(const Duration(milliseconds: 300));
      rig.out.clear();
      rig.send(SetLightingConfig(LightingConfig(effectId: 'html:demo')));
      await rig.advance(const Duration(milliseconds: 300));
      // Fans and board stay in Canvas: frames, no hardware mode.
      expect(rig.out.count('fanHw'), 0);
      expect(rig.out.calls, contains('fanFrames:1,2,3'));
      expect(rig.out.count('boardColors'), greaterThan(0));

      rig.out.clear();
      rig.send(SetLightingConfig(LightingConfig(effectId: 'spectrum')));
      await rig.advance(const Duration(milliseconds: 100));
      expect(hw(rig).every((c) => c.contains(':RainbowMorph:')), isTrue);
      expect(hw(rig).length, 3);
      rig.out.clear();
      await rig.advance(const Duration(milliseconds: 300));
      expect(rig.out.count('fanFrames'), 0);
      rig.module.stop();
    });

    testWidgets('scanner and color wave run the firmware fan modes', (
      tester,
    ) async {
      final rig = Rig(tester, LightingConfig(), autoHardware: true);
      await rig.advance(const Duration(milliseconds: 300));

      rig.out.clear();
      rig.out.fanHwLog.clear();
      rig.send(
        SetLightingConfig(
          LightingConfig(
            effectId: 'scanner',
            effectValues: const {
              'scanner': {'color': '#FF0000', 'background': '#000010'},
            },
          ),
        ),
      );
      await rig.advance(const Duration(milliseconds: 300));
      expect(rig.out.count('fanFrames'), 0);
      expect(hw(rig), ['fanHw:1:Scan:0', 'fanHw:2:Scan:0', 'fanHw:3:Scan:0']);
      expect(rig.out.fanHwLog.first.$2.colors.take(2), const [
        Rgb(255, 0, 0),
        Rgb(0, 0, 16),
      ]);
      // The board has no equivalent: it stays in Canvas.
      expect(rig.out.count('boardColors'), greaterThan(0));

      rig.out.clear();
      rig.send(
        SetLightingConfig(
          LightingConfig(
            effectId: 'colorWave',
            effectValues: const {
              'colorWave': {'color': '#FF0080', 'color2': '#0080FF'},
            },
          ),
        ),
      );
      await rig.advance(const Duration(milliseconds: 300));
      expect(hw(rig), [
        'fanHw:1:Taichi:1',
        'fanHw:2:Taichi:1',
        'fanHw:3:Taichi:1',
      ]);
      expect(rig.out.count('fanFrames'), 0);
      rig.module.stop();
    });

    testWidgets('fan canvas streaming stays at 2 fps by default', (
      tester,
    ) async {
      // Spectrum without autoHardware: the fans stream a changing canvas.
      final rig = Rig(tester, LightingConfig(), fanFrameGap: alv2SafeStreamGap);
      await rig.settle();
      rig.out.clear();
      await rig.advance(const Duration(seconds: 3));
      expect(rig.out.count('fanFrames'), inInclusiveRange(5, 7));
      // The other families keep the configured fps.
      expect(rig.out.count('chassis'), greaterThan(80));
      rig.module.stop();
    });

    test('the module default is the safe fan streaming gap', () {
      final m = LightingEngineModule(
        openOutputs: FakeOutputs.new,
        openWatcher: FakePowerWatcher.new,
        initial: LightingConfig(),
      );
      expect(m.fanFrameGap, alv2SafeStreamGap);
    });

    testWidgets('turning autoHardware off returns to streaming', (
      tester,
    ) async {
      final rig = Rig(tester, LightingConfig(), autoHardware: true);
      await rig.advance(const Duration(milliseconds: 300));
      rig.out.clear();
      rig.send(SetLightingConfig(LightingConfig(autoHardware: false)));
      await rig.advance(const Duration(milliseconds: 300));
      expect(rig.out.count('fanFrames'), greaterThan(0));
      rig.module.stop();
    });

    testWidgets('changing the effect speed resends the hardware', (
      tester,
    ) async {
      final rig = Rig(tester, LightingConfig(), autoHardware: true);
      await rig.advance(const Duration(milliseconds: 300));
      rig.out.clear();
      rig.send(
        SetLightingConfig(
          LightingConfig().withEffectValue('rainbowWave', 'speed', 100),
        ),
      );
      await rig.advance(const Duration(milliseconds: 100));
      expect(hw(rig), [
        'fanHw:1:Rainbow:4',
        'fanHw:2:Rainbow:4',
        'fanHw:3:Rainbow:4',
      ]);
      expect(zones(rig).length, 3);
      rig.module.stop();
    });

    testWidgets('breathing: canvas follows the firmware period and phase', (
      tester,
    ) async {
      final config = LightingConfig(
        effectId: 'breathing',
        effectValues: const {
          'breathing': {'color': '#FF0000', 'speed': 30},
        },
      );
      final rig = Rig(tester, config, autoHardware: true, startNow: false);
      double secs() => rig.elapsed.inMicroseconds / 1e6;
      // Every Breathing send restarts the firmware clock (the resend ~1 s
      // later included), so the canvas re-anchors on each of them.
      final anchors = <double>[];
      final chassisAt = <double>[];
      rig.out
        ..onFanHw = (_, c) {
          if (c.mode == 'Breathing') anchors.add(secs());
        }
        ..onChassisSend = () => chassisAt.add(secs());

      // Red level the firmware shows at [t] for a mode sent at [anchor]: it
      // starts bright and is dark at the first trough after the send.
      int firmwareRed(double t, double anchor, num speed) {
        final period = alv2BreathingPeriod(speed).inMicroseconds / 1e6;
        final trough =
            breathingFirstTroughPhase * period +
            breathingFirstTroughDelay.inMicroseconds / 1e6;
        final u = (t - anchor - trough) / period;
        return (255 * (0.5 - 0.5 * math.cos(2 * math.pi * u))).floor();
      }

      // Chassis frames from [from] on must match the curve of the latest
      // Breathing send strictly before them. The tolerance covers rounding
      // and the 1 ms ITE lead; a 1 s phase error is off by up to ~40.
      var checked = 0;
      void expectInPhase(int from, num speed) {
        for (var i = from; i < chassisAt.length; i++) {
          final t = chassisAt[i];
          final before = anchors.where((a) => a < t);
          if (before.isEmpty) continue;
          expect(
            rig.out.chassisLog[i].first.r,
            closeTo(firmwareRed(t, before.last, speed), 3),
            reason: 'chassis frame at $t s',
          );
          checked++;
        }
      }

      rig.start();
      await rig.advance(const Duration(milliseconds: 500));
      expect(hw(rig), [
        'fanHw:1:Breathing:1',
        'fanHw:2:Breathing:1',
        'fanHw:3:Breathing:1',
      ]);
      // No ITE pulse matched the fan period: the board stays in Canvas.
      expect(zones(rig), isEmpty);
      expect(rig.out.count('fanFrames'), 0);

      // A full period, across the resend ~1 s after the first send.
      await rig.advance(alv2BreathingPeriod(30) + const Duration(seconds: 1));
      expect(anchors, hasLength(6));
      expect(anchors[3] - anchors[0], closeTo(1, 0.05));
      expectInPhase(0, 30);
      expect(checked, greaterThan(100));

      // Changing the speed mid-effect sends a new mode: the phase restarts
      // with it and the canvas switches to the new period.
      final from = chassisAt.length;
      checked = 0;
      rig.send(
        SetLightingConfig(config.withEffectValue('breathing', 'speed', 100)),
      );
      await rig.advance(alv2BreathingPeriod(100) + const Duration(seconds: 1));
      expect(anchors, hasLength(12));
      expectInPhase(from, 100);
      expect(checked, greaterThan(100));
      rig.module.stop();
    });

    testWidgets('hardware modes are sent again ~1 s after a change', (
      tester,
    ) async {
      final rig = Rig(tester, withModes(LightingConfig(), hardwareModes));
      await rig.advance(const Duration(milliseconds: 200));
      expect(rig.out.count('fanHw'), 3);
      expect(rig.out.count('zone'), 3);

      rig.out.clear();
      await rig.advance(const Duration(milliseconds: 600));
      expect(rig.out.count('fanHw'), 0);
      await rig.advance(const Duration(milliseconds: 400));
      expect(rig.out.count('fanHw'), 3);
      expect(rig.out.count('zone'), 3);

      // The resend does not schedule another one.
      rig.out.clear();
      await rig.advance(const Duration(seconds: 3));
      expect(rig.out.count('fanHw'), 0);
      rig.module.stop();
    });

    testWidgets('manual Hardware and Fixed groups are not touched', (
      tester,
    ) async {
      final base = withModes(LightingConfig(), {
        LightDeviceId.alv2Group1: LightMode.hardware,
        LightDeviceId.alv2Group2: LightMode.fixed,
      });
      final rig = Rig(tester, base, autoHardware: true);
      await rig.advance(const Duration(milliseconds: 500));
      // Group 1 keeps its own mode (StaticColor, speed 2); group 3 is auto.
      expect(hw(rig), ['fanHw:1:StaticColor:2', 'fanHw:3:Rainbow:1']);
      // Group 2 (fixed) is still streamed.
      expect(rig.out.calls.where((c) => c.startsWith('fanFrames')).toSet(), {
        'fanFrames:2',
      });
      rig.module.stop();
    });
  });

  group('HTML effect frames', () {
    testWidgets('sampled colors reach the case and stale effects are dropped', (
      tester,
    ) async {
      final cfg = LightingConfig(effectId: 'html:rainbow');
      final rig = Rig(tester, cfg);
      await rig.settle();
      rig.out.clear();

      const color = Rgb(11, 22, 33);
      rig.send(
        SetHtmlEffectFrame(cfg.effectId, {
          LightDeviceId.chassis: List.filled(chassisLedCount, color),
        }),
      );
      await rig.advance(const Duration(milliseconds: 50));
      expect(rig.out.chassisLog, isNotEmpty);
      expect(rig.out.chassisLog.last, everyElement(color));

      // A frame from another effect must not be applied.
      rig.send(
        SetHtmlEffectFrame('html:other', {
          LightDeviceId.chassis: List.filled(
            chassisLedCount,
            const Rgb(200, 0, 0),
          ),
        }),
      );
      rig.out.clear();
      await rig.advance(const Duration(milliseconds: 50));
      // Any frame still in flight keeps the old colors, never the stale red.
      for (final leds in rig.out.chassisLog) {
        expect(leds, everyElement(color));
      }

      const next = Rgb(1, 2, 3);
      rig.send(
        SetHtmlEffectFrame(cfg.effectId, {
          LightDeviceId.chassis: List.filled(chassisLedCount, next),
        }),
      );
      await rig.advance(const Duration(milliseconds: 50));
      expect(rig.out.chassisLog.last, everyElement(next));
      rig.module.stop();
    });

    testWidgets('fixed mode wins over the sampled frame', (tester) async {
      final base = LightingConfig(effectId: 'html:rainbow');
      final cfg = base.withDevice(
        LightDeviceId.chassis,
        base
            .device(LightDeviceId.chassis)
            .copyWith(mode: LightMode.fixed, fixedColor: const Rgb(90, 80, 70)),
      );
      final rig = Rig(tester, cfg);
      await rig.settle();
      rig.out.clear();
      rig.send(
        SetHtmlEffectFrame(cfg.effectId, {
          LightDeviceId.chassis: List.filled(
            chassisLedCount,
            const Rgb(1, 2, 3),
          ),
        }),
      );
      await rig.advance(const Duration(milliseconds: 50));
      expect(rig.out.chassisLog.last, everyElement(const Rgb(90, 80, 70)));
      rig.module.stop();
    });
  });
}
