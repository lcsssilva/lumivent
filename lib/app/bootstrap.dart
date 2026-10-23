// Composition root: opens configuration, starts the engine with its modules,
// connects each module's ports to implementations, and prepares the window and tray.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../core/engine/isolate_engine.dart';
import '../core/engine/engine_api.dart';
import '../core/persistence/config_store.dart';
import '../features/fans/fans.dart';
import '../features/lighting/lighting.dart';
import '../features/preferences/preferences.dart';
import '../features/system/system.dart';
import 'we_app.dart';
import 'desktop/desktop_actions.dart';
import 'desktop/desktop_integration.dart';
import 'engine_modules.dart';
import 'engine_init.dart';
import 'licenses.dart';
import 'ui_language_binding.dart';

Future<void> bootstrap(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  registerBundledLicenses();

  final store = await ConfigStore.open(defaultConfigDir());
  final lighting = LightingModule.repository(store).load();
  final fans = FansModule.repository(store).load();
  // The LED loop starts at the saved FPS, before the main container exists.
  final fps = PreferencesModule.repository(store).load().effectsFps;
  final engine = await IsolateEngine.spawn(
    buildEngineModules,
    EngineInit(lighting: lighting, lightingFps: fps, fans: fans),
  );

  ProviderContainer? container;
  DesktopIntegration? desktop;
  try {
    container = ProviderContainer(
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
        desktopActionsProvider.overrideWith((ref) => desktop!),
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
    desktop = DesktopIntegration(container);
    await desktop.init(startMinimized: args.contains('--minimized'));
  } on Object {
    // The engine already drives the fans and LEDs: release it before the
    // failure screen, or the hardware keeps running with no way to quit.
    await releaseAfterStartupFailure(
      engine: engine,
      container: container,
      releaseDesktop: desktop?.release,
    );
    rethrow;
  }

  runApp(UncontrolledProviderScope(container: container, child: const WeApp()));
}

/// Undoes what startup acquired after the engine spawned, in reverse order:
/// window/tray hooks, providers (the effect renderer), then the engine, which
/// stops its modules. A cleanup failure is logged and the next step still runs.
@visibleForTesting
Future<void> releaseAfterStartupFailure({
  required EngineApi engine,
  ProviderContainer? container,
  Future<void> Function()? releaseDesktop,
}) async {
  Future<void> cleanupStep(
    String stepName,
    FutureOr<void> Function() run,
  ) async {
    try {
      await run();
    } on Object catch (error, stack) {
      stderr.writeln(
        'Lumivent startup cleanup ($stepName) failed: $error\n$stack',
      );
    }
  }

  if (releaseDesktop != null) await cleanupStep('desktop', releaseDesktop);
  if (container != null) await cleanupStep('providers', container.dispose);
  await cleanupStep('engine', engine.shutdown);
}
