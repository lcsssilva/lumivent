import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/core/engine/isolate_engine.dart';
import 'package:lumivent/features/lighting/application/lighting_notifier.dart';
import 'package:lumivent/features/lighting/application/set_argb_off.dart';
import 'package:lumivent/features/lighting/application/set_lighting_config.dart';
import 'package:lumivent/features/lighting/domain/canvas_rect.dart';
import 'package:lumivent/features/lighting/domain/light_device.dart';
import 'package:lumivent/features/lighting/domain/lighting_config.dart';
import 'package:lumivent/features/lighting/presentation/view_models/lighting_ui_state.dart';
import 'package:lumivent/features/lighting/presentation/view_models/lighting_view_model.dart';

import '../../fake_engine.dart';
import '../../support/memory_lighting_repository.dart';

void main() {
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
}
