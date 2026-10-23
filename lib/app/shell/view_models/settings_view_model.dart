import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/persistence/config_store.dart';
import '../../../features/devices/devices.dart';
import '../../../features/preferences/preferences.dart';
import '../../../features/system/system.dart';
import '../../config_transfer.dart';
import '../../desktop/desktop_actions.dart';
import 'settings_ui_state.dart';

/// Presentation state and actions of the settings view: preferences,
/// autostart, device detection, diagnostics, and configuration transfer.
class SettingsViewModel extends Notifier<SettingsUiState> {
  @override
  SettingsUiState build() => SettingsUiState(
    preferences: ref.watch(preferencesProvider),
    trayAvailable: ref.watch(desktopActionsProvider).trayAvailable,
    autostart: ref.watch(autostartProvider),
    autostartLocation: ref.watch(autostartServiceProvider).location,
    checks: [
      ...ref.watch(diagnosticsProvider),
      ...ref.watch(runtimeChecksProvider),
    ],
    devices: ref.watch(devicesProvider),
  );

  void changePreferences(Preferences Function(Preferences) change) =>
      ref.read(preferencesProvider.notifier).change(change);

  /// Turns autostart on or off; a failure is reported in the state.
  Future<void> setAutostart(bool enabled) =>
      ref.read(autostartProvider.notifier).setEnabled(enabled);

  void rescanDevices() => ref.read(devicesProvider.notifier).rescan();

  /// The whole configuration as JSON, ready to save.
  String exportConfiguration() => exportConfig(ref.read(configStoreProvider));

  /// Imports a configuration file and reloads the affected modules. Returns
  /// the path of the backup taken first. Errors reach the caller with
  /// messages from [strings].
  Future<String> importConfiguration(
    Stream<List<int>> file, {
    required AppStrings strings,
  }) async {
    final text = await readImportText(file, strings: strings);
    final transfer = ref.read(configTransferProvider);
    await transfer.importText(text, strings: strings);
    return transfer.backupPath;
  }
}

final settingsViewModelProvider =
    NotifierProvider.autoDispose<SettingsViewModel, SettingsUiState>(
      SettingsViewModel.new,
    );
