import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/preferences/application/preferences_notifier.dart';
import 'package:lumivent/core/engine/isolate_engine.dart';
import 'package:lumivent/features/lighting/application/messages/identify_fan_group.dart';
import 'package:lumivent/features/lighting/application/status/light_output_state.dart';
import 'package:lumivent/features/lighting/application/status/light_output_status.dart';
import 'package:lumivent/features/lighting/application/messages/lighting_status.dart';
import 'package:lumivent/features/lighting/domain/hardware_mode/hardware_equivalent.dart';
import 'package:lumivent/features/lighting/application/lighting_notifier.dart';
import 'package:lumivent/features/lighting/application/messages/set_argb_off.dart';
import 'package:lumivent/features/lighting/application/messages/set_lighting_config.dart';
import 'package:lumivent/features/lighting/domain/canvas/canvas_rect.dart';
import 'package:lumivent/features/lighting/domain/hardware_mode/fan_hardware_mode.dart';
import 'package:lumivent/features/lighting/domain/hardware_mode/fan_mode_name.dart';
import 'package:lumivent/features/lighting/domain/light_device.dart';
import 'package:lumivent/features/lighting/domain/config/lighting_config.dart';
import 'package:lumivent/features/lighting/presentation/view_models/lighting_ui_state.dart';
import 'package:lumivent/features/lighting/presentation/view_models/lighting_view_model.dart';

import '../../fake_engine.dart';
import '../../support/memory_lighting_repository.dart';
import '../../support/memory_preferences_repository.dart';

void main() {
  const modes = [
    FanHardwareMode(name: 'Wave', hasSpeed: true, colorCount: 1),
    FanHardwareMode(name: 'Wave_Inner', scope: FanModeSuffix.inner),
  ];
  late FakeEngine engine;
  late MemoryLightingRepository repo;
  late ProviderContainer container;

  setUp(() {
    engine = FakeEngine();
    repo = MemoryLightingRepository()..config = LightingConfig(argbOff: true);
    container = ProviderContainer(
      overrides: [
        engineProvider.overrideWithValue(engine),
        lightingRepositoryProvider.overrideWithValue(repo),
        fanHardwareModesProvider.overrideWithValue(modes),
        preferencesRepositoryProvider.overrideWithValue(
          MemoryPreferencesRepository(),
        ),
      ],
    );
    container.listen(lightingViewModelProvider, (_, _) {});
  });
  tearDown(() => container.dispose());

  LightingViewModel viewModel() =>
      container.read(lightingViewModelProvider.notifier);
  LightingUiState ui() => container.read(lightingViewModelProvider);

  test('the selected device survives configuration changes', () {
    viewModel().selectDevice(LightDeviceId.gpu);
    viewModel().setBrightness(.3);
    expect(ui().config.brightness, .3);
    expect(ui().selectedDevice, LightDeviceId.gpu);

    viewModel().selectDevice(null);
    expect(ui().selectedDevice, isNull);
  });

  test('the fan hub modes come from the injected table', () {
    expect(ui().fanHardwareModes, same(modes));
    viewModel().selectDevice(LightDeviceId.alv2Group1);
    expect(ui().fanHardwareModes, same(modes));
  });

  test('global settings and the effect go to the engine', () {
    viewModel().setOffOnSleep(false);
    viewModel().setAutoHardware(false);
    viewModel().selectEffect('scanner');
    final config = container.read(lightingProvider);
    expect(config.offOnSleep, isFalse);
    expect(config.autoHardware, isFalse);
    expect(config.effectId, 'scanner');
    expect(engine.sent.whereType<SetLightingConfig>(), hasLength(3));
  });

  test('placing a device keeps its other settings', () {
    const rect = CanvasRect(10, 20, 30, 40);
    final before = container.read(lightingProvider).device(LightDeviceId.ram1);
    viewModel().placeDevice(LightDeviceId.ram1, rect);
    final after = container.read(lightingProvider).device(LightDeviceId.ram1);
    expect(after.placement, rect);
    expect(after.mode, before.mode);
    expect(after.enabled, before.enabled);
  });

  test('turning ARGB on is sent and saved right away', () async {
    viewModel().turnArgbOn();
    expect(container.read(lightingProvider).argbOff, isFalse);
    expect(engine.sent.whereType<SetArgbOff>().single.off, isFalse);
    expect(repo.config.argbOff, isFalse);
  });

  test('panel edits and identify go to the lighting notifier', () {
    viewModel().edit((c) => c.withFanQuantity(2, 5));
    expect(container.read(lightingProvider).fanQuantity[2], 5);
    viewModel().identify(3);
    expect(engine.sent.whereType<IdentifyFanGroup>().single.group, 3);
  });

  test(
    'device status and auto hardware come from the engine and config',
    () async {
      expect(ui().deviceStatus(LightDeviceId.gpu), isNull);
      engine.emit(
        LightingStatus(const {
          LightDeviceId.gpu: LightOutputStatus(LightOutputState.unavailable),
        }, fps: 30),
      );
      await Future<void>.delayed(Duration.zero);
      expect(
        ui().deviceStatus(LightDeviceId.gpu)?.state,
        LightOutputState.unavailable,
      );
      expect(ui().autoHardware, autoHardwareDevices(ui().config));
    },
  );
}
