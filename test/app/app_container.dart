import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumivent/app/desktop/desktop_actions.dart';
import 'package:lumivent/app/ui_language_binding.dart';
import 'package:lumivent/core/engine/isolate_engine.dart';
import 'package:lumivent/core/persistence/config_store.dart';
import 'package:lumivent/features/fans/fans.dart';
import 'package:lumivent/features/lighting/lighting.dart';
import 'package:lumivent/features/preferences/preferences.dart';
import 'package:lumivent/features/system/system.dart';

import '../fake_engine.dart';
import 'fake_autostart.dart';
import 'fake_desktop.dart';
import 'no_diagnostics.dart';

/// A container wired like the app, with fakes for the engine and the OS.
ProviderContainer appContainer(
  ConfigStore store,
  FakeEngine engine,
  FakeAutostart autostart,
) => ProviderContainer(
  overrides: [
    engineProvider.overrideWithValue(engine),
    configStoreProvider.overrideWithValue(store),
    ...PreferencesModule.overrides(store),
    ...LightingModule.overrides(store),
    ...FansModule.overrides(store),
    uiLanguageFromPreferences(),
    autostartServiceProvider.overrideWithValue(autostart),
    environmentDiagnosticsProvider.overrideWithValue(NoDiagnostics()),
    desktopActionsProvider.overrideWithValue(FakeDesktop()),
  ],
);
