import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/app/navigation/app_route.dart';
import 'package:lumivent/app/shell/view_models/shell_ui_state.dart';
import 'package:lumivent/app/shell/view_models/shell_view_model.dart';
import 'package:lumivent/core/persistence/config_store.dart';
import 'package:lumivent/features/devices/devices.dart';
import 'package:lumivent/features/lighting/lighting.dart';
import 'package:lumivent/features/monitoring/monitoring.dart';
import 'package:lumivent/features/preferences/preferences.dart';

import '../fake_engine.dart';
import 'app_container.dart';
import 'fake_autostart.dart';

void main() {
  late Directory tmp;
  late FakeEngine engine;
  late ProviderContainer container;

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('lumivent-shell-vm-');
    engine = FakeEngine();
    container = appContainer(
      await ConfigStore.open(tmp),
      engine,
      FakeAutostart(),
    );
    container.listen(shellViewModelProvider, (_, _) {});
  });
  tearDown(() {
    container.dispose();
    tmp.deleteSync(recursive: true);
  });

  ShellViewModel viewModel() => container.read(shellViewModelProvider.notifier);
  ShellUiState ui() => container.read(shellViewModelProvider);

  test('navigation changes the route', () {
    expect(ui().route, AppRoute.monitoring);
    viewModel().go(AppRoute.fans);
    expect(ui().route, AppRoute.fans);
  });

  test('the ARGB switch is sent to the engine and shown', () {
    expect(ui().argbOff, isFalse);
    viewModel().setArgbOff(true);
    expect(ui().argbOff, isTrue);
    expect(engine.sent.whereType<SetArgbOff>().single.off, isTrue);
  });

  test('sensors, devices, and the unit follow the application', () async {
    expect(ui().latestSensors, isNull);
    expect(ui().devices, isNull);
    final snapshot = DeviceSnapshot(
      devices: const [],
      conflicts: const [],
      scannedAt: DateTime(2026, 10, 23),
    );
    engine
      ..emit(
        SensorsUpdated(SensorSample(DateTime(2026), {Metrics.cpuTctl: 55})),
      )
      ..emit(DevicesChanged(snapshot));
    await Future<void>.delayed(Duration.zero);
    container
        .read(preferencesProvider.notifier)
        .change((p) => p.copyWith(temperatureUnit: TemperatureUnit.fahrenheit));
    expect(ui().latestSensors?[Metrics.cpuTctl], 55);
    expect(ui().devices, same(snapshot));
    expect(ui().temperatureUnit, TemperatureUnit.fahrenheit);
  });
}
