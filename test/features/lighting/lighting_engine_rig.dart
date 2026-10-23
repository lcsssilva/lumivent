import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/core/engine/engine_command.dart';
import 'package:lumivent/core/engine/engine_event.dart';
import 'package:lumivent/features/lighting/application/lighting_engine_module.dart';
import 'package:lumivent/features/lighting/application/messages/set_lighting_config.dart';
import 'package:lumivent/features/lighting/application/messages/argb_state_changed.dart';
import 'package:lumivent/features/lighting/application/messages/lighting_status.dart';
import 'package:lumivent/features/lighting/domain/config/lighting_config.dart';

import 'lighting_engine_test.dart';
import 'fake_outputs.dart';
import 'fake_power_watcher.dart';

/// Module + fakes + virtual clock driven by `tester.pump`.
class LightingEngineRig {
  LightingEngineRig(
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
