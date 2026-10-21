// Composition root: opens configuration, starts the engine with its modules,
// connects each module's ports to implementations, and prepares the window and tray.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../core/engine/engine_host.dart';
import '../core/persistence/config_store.dart';
import '../features/fans/fans.dart';
import '../features/lighting/lighting.dart';
import '../features/preferences/preferences.dart';
import '../features/system/system.dart';
import 'app.dart';
import 'desktop/desktop_actions.dart';
import 'desktop/desktop_controller.dart';
import 'engine_modules.dart';
import 'licenses.dart';
import 'ui_language_binding.dart';

Future<void> bootstrap(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  registerBundledLicenses();

  final store = await ConfigStore.open(defaultConfigDir());
  final lighting = LightingModule.repository(store).load();
  final fans = FansModule.repository(store).load();
  final fps = _initialFps(store);
  final engine = await IsolateEngine.spawn(
    buildEngineModules,
    EngineInit(lighting: lighting, lightingFps: fps, fans: fans),
  );

  late final DesktopController desktop;
  final container = ProviderContainer(
    overrides: [
      configStoreProvider.overrideWithValue(store),
      engineProvider.overrideWithValue(engine),
      ...PreferencesModule.overrides(store),
      ...LightingModule.overrides(store),
      ...FansModule.overrides(store),
      // The lighting screen shows the group names set on the fans page.
      fanGroupNamesProvider.overrideWith(
        (ref) => [for (final g in ref.watch(fansProvider).groups) g.name],
      ),
      ...SystemModule.overrides(executable: Platform.resolvedExecutable),
      desktopActionsProvider.overrideWith((ref) => desktop),
      uiLanguageFromPreferences(),
    ],
  );
  // The LED loop follows the FPS preference.
  container.listen(preferencesProvider.select((p) => p.effectsFps), (
    prev,
    fps,
  ) {
    if (prev != fps) engine.send(SetLightingFps(fps));
  });
  // The HTML effect renderer must keep running while the window is hidden and
  // regardless of the visible page (plan §5.5).
  container.listen(htmlEffectRunnerProvider, (_, _) {});
  desktop = DesktopController(container);
  await desktop.init(startMinimized: args.contains('--minimized'));

  runApp(UncontrolledProviderScope(container: container, child: const WeApp()));
}

/// FPS of the effects saved in the preferences (before the main container exists).
int _initialFps(ConfigStore store) {
  final container = ProviderContainer(
    overrides: PreferencesModule.overrides(store),
  );
  try {
    return container.read(preferencesProvider).effectsFps;
  } finally {
    container.dispose();
  }
}
