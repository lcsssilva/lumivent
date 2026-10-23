import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/app/shell/view_models/settings_ui_state.dart';
import 'package:lumivent/app/shell/view_models/settings_view_model.dart';
import 'package:lumivent/core/i18n/app_strings.dart';
import 'package:lumivent/core/persistence/config_store.dart';
import 'package:lumivent/features/devices/devices.dart';

import '../fake_engine.dart';
import 'app_container.dart';
import 'fake_autostart.dart';

void main() {
  late Directory tmp;
  late ConfigStore store;
  late FakeEngine engine;
  late FakeAutostart autostart;
  late ProviderContainer container;

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('lumivent-settings-vm-');
    store = await ConfigStore.open(tmp);
    engine = FakeEngine();
    autostart = FakeAutostart();
    container = appContainer(store, engine, autostart);
    container.listen(settingsViewModelProvider, (_, _) {});
  });
  tearDown(() {
    container.dispose();
    tmp.deleteSync(recursive: true);
  });

  SettingsViewModel viewModel() =>
      container.read(settingsViewModelProvider.notifier);
  SettingsUiState ui() => container.read(settingsViewModelProvider);

  test('preferences change and are shown', () {
    expect(ui().trayAvailable, isTrue);
    viewModel().changePreferences((p) => p.copyWith(effectsFps: 15));
    expect(ui().preferences.effectsFps, 15);
  });

  test('autostart is turned on through the service', () async {
    await container.read(settingsViewModelProvider.notifier).setAutostart(true);
    expect(autostart.enabled, isTrue);
    expect(ui().autostart.value?.enabled, isTrue);
    expect(ui().autostartLocation, autostart.location);
  });

  test('detecting again asks the engine for a scan', () {
    viewModel().rescanDevices();
    expect(engine.sent.whereType<RescanDevices>(), hasLength(1));
  });

  test('an exported configuration imports back and reloads', () async {
    viewModel().changePreferences((p) => p.copyWith(effectsFps: 15));
    await store.flush();
    final exported = viewModel().exportConfiguration();
    viewModel().changePreferences((p) => p.copyWith(effectsFps: 60));
    await store.flush();

    final backup = await viewModel().importConfiguration(
      Stream.value(utf8.encode(exported)),
      strings: AppStrings.en,
    );
    expect(File(backup).existsSync(), isTrue);
    expect(ui().preferences.effectsFps, 15);
  });

  test('an invalid file reaches the caller with a localized message', () {
    expect(
      viewModel().importConfiguration(
        Stream.value(const [0xff, 0xfe]),
        strings: AppStrings.pt,
      ),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          AppStrings.pt.shell.invalidJson,
        ),
      ),
    );
  });
}
