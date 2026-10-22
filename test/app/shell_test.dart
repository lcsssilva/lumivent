import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/app/app.dart';
import 'package:lumivent/app/bootstrap_failure.dart';
import 'package:lumivent/app/desktop/desktop_actions.dart';
import 'package:lumivent/app/navigation/app_route.dart';
import 'package:lumivent/app/shell/topbar.dart';
import 'package:lumivent/app/ui_language_binding.dart';
import 'package:lumivent/core/engine/engine_host.dart';
import 'package:lumivent/core/i18n/app_strings.dart';
import 'package:lumivent/core/i18n/strings_provider.dart';
import 'package:lumivent/core/persistence/config_store.dart';
import 'package:lumivent/features/devices/devices.dart';
import 'package:lumivent/features/fans/fans.dart';
import 'package:lumivent/features/lighting/lighting.dart';
import 'package:lumivent/features/preferences/preferences.dart';
import 'package:lumivent/features/system/system.dart';

import '../fakes.dart';

class FakeDesktop implements DesktopActions {
  @override
  bool get trayAvailable => true;

  @override
  Future<void> quit() async {}
}

class FakeAutostart implements AutostartService {
  bool enabled = false;

  @override
  String get location => '/home/u/.config/systemd/user/lumivent.service';

  @override
  Future<AutostartState> status() async =>
      AutostartState(enabled: enabled, stale: false);

  @override
  Future<void> enable() async => enabled = true;

  @override
  Future<void> disable() async => enabled = false;
}

class NoDiagnostics implements EnvironmentDiagnostics {
  @override
  List<DiagnosticCheck> run() => const [];
}

final _snapshot = DeviceSnapshot(
  devices: const [
    DeviceInfo(
      id: 'alv2',
      kind: DeviceKind.fans,
      label: DeviceLabel.alv2Fans,
      model: 'Lian Li UNI FAN AL V2',
      status: DeviceStatus.ok,
      detail: 'firmware v0.4 · /dev/hidraw8',
    ),
    DeviceInfo(
      id: 'fury-1',
      kind: DeviceKind.memory,
      label: DeviceLabel.memoryModule,
      slot: 1,
      model: 'Kingston Fury DDR5',
      status: DeviceStatus.noPermission,
      issue: DeviceIssue.udevRules,
    ),
    DeviceInfo(
      id: 'gpu',
      kind: DeviceKind.gpu,
      label: DeviceLabel.graphicsCard,
      model: 'Gigabyte RX 9060 XT',
      status: DeviceStatus.unsupported,
    ),
  ],
  conflicts: const ['OpenRGB'],
  scannedAt: DateTime(2026, 10, 18),
);

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

void main() {
  late Directory tmp;
  late ConfigStore store;
  late FakeEngine engine;
  late FakeAutostart autostart;
  late ProviderContainer container;

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('lumivent-shell-');
    store = await ConfigStore.open(tmp);
    // The historical shell tests assert Portuguese text; English is covered by
    // the language-switch test below.
    await store.saveSection(
      'preferences',
      const Preferences(language: AppLanguage.pt).toJson(),
    );
    engine = FakeEngine();
    autostart = FakeAutostart();
    container = appContainer(store, engine, autostart);
  });

  tearDown(() {
    container.dispose();
    tmp.deleteSync(recursive: true);
  });

  Future<void> pumpApp(
    WidgetTester tester, {
    Size size = const Size(1400, 1000),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const WeApp()),
    );
  }

  testWidgets('opens Monitoring and navigates through the sidebar', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.text('Sensores da CPU, GPU, placa-mãe e SSDs'), findsOneWidget);
    expect(find.text('Armazenamento'), findsOneWidget);

    await tester.tap(find.text('Fans'));
    await tester.pumpAndSettle();
    expect(find.byType(FansPage), findsOneWidget);

    await tester.tap(find.text('Configurações').first);
    await tester.pumpAndSettle();
    expect(find.text('Iniciar com o sistema'), findsOneWidget);
    expect(find.text('Manter na bandeja ao fechar'), findsOneWidget);
  });

  testWidgets('bootstrap failure shows diagnostic details and config action', (
    tester,
  ) async {
    await tester.pumpWidget(
      BootstrapFailureApp(
        error: StateError('config directory is not writable'),
        configDir: tmp,
      ),
    );

    expect(find.text('Lumivent could not start'), findsOneWidget);
    expect(
      find.textContaining('config directory is not writable'),
      findsOneWidget,
    );
    expect(find.text('Open configuration folder'), findsOneWidget);
  });

  testWidgets('engine devices appear in the sidebar and Settings', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.text('Detectando…'), findsOneWidget);

    engine.emit(DevicesChanged(_snapshot));
    await tester.pump();
    // Outside Monitoring, which also has a "GPU" card.
    container.read(routeProvider.notifier).go(AppRoute.explore);
    await tester.pumpAndSettle();
    expect(find.text('AL V2'), findsOneWidget);
    expect(find.text('RAM'), findsOneWidget);
    expect(find.text('GPU'), findsOneWidget);

    container.read(routeProvider.notifier).go(AppRoute.settings);
    await tester.pumpAndSettle();
    expect(find.text('firmware v0.4 · /dev/hidraw8'), findsOneWidget);
    expect(find.text('Sem permissão'), findsOneWidget);
    expect(find.text('Sem suporte'), findsOneWidget);
    expect(find.textContaining('OpenRGB está rodando'), findsOneWidget);

    await tester.tap(find.text('Detectar novamente'));
    expect(engine.sent.whereType<RescanDevices>(), hasLength(1));
  });

  // Writing config.json is covered by lighting_test (real IO does not advance
  // on the testWidgets fake clock).
  testWidgets('top bar ARGB switch turns off and notifies the engine', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.byType(Switch).first);
    await tester.pump();
    expect(find.text('ARGB desligado'), findsOneWidget);
    expect(engine.sent.whereType<SetArgbOff>().single.off, isTrue);
    expect(container.read(lightingProvider).argbOff, isTrue);
  });

  testWidgets('autostart is enabled by the switch', (tester) async {
    await pumpApp(tester);
    container.read(routeProvider.notifier).go(AppRoute.settings);
    await tester.pumpAndSettle();
    final sw = find.descendant(
      of: find
          .ancestor(
            of: find.text('Iniciar com o sistema'),
            matching: find.byType(Row),
          )
          .first,
      matching: find.byType(Switch),
    );
    await tester.tap(sw);
    await tester.pumpAndSettle();
    expect(autostart.enabled, isTrue);
  });

  testWidgets('language switch applies immediately and persists', (
    tester,
  ) async {
    await pumpApp(tester);
    container.read(routeProvider.notifier).go(AppRoute.settings);
    await tester.pumpAndSettle();
    expect(find.text('Idioma'), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Language'), findsOneWidget);
    expect(container.read(preferencesProvider).language, AppLanguage.en);
    expect(store.section('preferences')['language'], 'en');

    await tester.tap(find.text('Português'));
    await tester.pumpAndSettle();
    expect(find.text('Idioma'), findsOneWidget);
    expect(container.read(preferencesProvider).language, AppLanguage.pt);
  });

  // Real IO does not advance on the testWidgets fake clock, so the restart is
  // checked outside the widget tree.
  test('the chosen language survives a restart', () async {
    container
        .read(preferencesProvider.notifier)
        .change((p) => p.copyWith(language: AppLanguage.pt));
    await store.flush();

    final restarted = appContainer(
      await ConfigStore.open(tmp),
      FakeEngine(),
      FakeAutostart(),
    );
    addTearDown(restarted.dispose);
    expect(restarted.read(preferencesProvider).language, AppLanguage.pt);
    expect(restarted.read(stringsProvider), same(AppStrings.pt));
  });

  testWidgets('a fresh install opens in English', (tester) async {
    final freshDir = Directory.systemTemp.createTempSync('lumivent-fresh-');
    addTearDown(() => freshDir.deleteSync(recursive: true));
    final fresh = (await tester.runAsync(() => ConfigStore.open(freshDir)))!;
    container.dispose();
    container = appContainer(fresh, engine, autostart);

    await pumpApp(tester);
    expect(container.read(preferencesProvider).language, AppLanguage.en);
    expect(find.text(AppRoute.monitoring.subtitle(AppStrings.en)), findsOne);
    expect(find.text(AppRoute.monitoring.label(AppStrings.pt)), findsNothing);
  });

  test('every saved language maps to a catalog language', () {
    for (final language in AppLanguage.values) {
      expect(uiLanguageOf(language).name, language.name);
    }
  });

  // Manual QA §7 #12: the narrowest window (the minimum size) and the default
  // size render every page without overflow in both languages.
  for (final language in AppLanguage.values) {
    for (final size in const [Size(1040, 680), Size(1280, 800)]) {
      final label = '${size.width.toInt()}x${size.height.toInt()}';
      testWidgets('no overflow in ${language.name} at $label', (tester) async {
        container
            .read(preferencesProvider.notifier)
            .change((p) => p.copyWith(language: language));
        await pumpApp(tester, size: Size(size.width, size.height - 32));
        engine.emit(DevicesChanged(_snapshot));

        for (final route in AppRoute.values) {
          container.read(routeProvider.notifier).go(route);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          expect(tester.takeException(), isNull, reason: route.name);
          final labelFinder = find.descendant(
            of: find.byType(TopBar),
            matching: find.text(
              route.label(
                language == AppLanguage.en ? AppStrings.en : AppStrings.pt,
              ),
            ),
          );
          if (labelFinder.evaluate().isNotEmpty) {
            final paragraph = tester.renderObject<RenderParagraph>(
              labelFinder.first,
            );
            expect(
              paragraph.didExceedMaxLines,
              isFalse,
              reason: '${route.name} label at $label',
            );
          }
        }
      });
    }
  }

  testWidgets('English catalog renders every route', (tester) async {
    container
        .read(preferencesProvider.notifier)
        .change((p) => p.copyWith(language: AppLanguage.en));
    await pumpApp(tester);

    for (final route in AppRoute.values) {
      container.read(routeProvider.notifier).go(route);
      // Some pages animate continuously; a single frame is enough to check the
      // shell labels without waiting for the page to settle.
      await tester.pump();
      expect(
        find.text(route.label(AppStrings.en)),
        findsWidgets,
        reason: 'label ${route.name}',
      );
      expect(
        find.text(route.subtitle(AppStrings.en)),
        findsOneWidget,
        reason: 'subtitle ${route.name}',
      );
    }
  });

  // A failed configuration write is notified by the shell. Like the restart
  // test above, the real IO needs runAsync to advance on the fake clock.
  testWidgets('a failed configuration write shows the notification', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.pump();

    // Writes fail while the config file path exists as a directory: the
    // rename of the temporary file cannot replace a directory. The failure
    // is the expected subject of the test and the shell announces it, so it
    // is not re-checked here.
    store.file.deleteSync();
    Directory('${tmp.path}/config.json').createSync();
    await tester.runAsync(
      () => store
          .saveSection('lighting', {'argbOff': true})
          .catchError((Object _) {}),
    );
    await tester.pump();
    expect(
      find.textContaining('Não foi possível salvar suas alterações'),
      findsOneWidget,
    );

    // A later successful write recovers the pending change on disk.
    Directory('${tmp.path}/config.json').deleteSync();
    final onDisk = await tester.runAsync(() async {
      await store.saveSection('lighting', {'argbOff': false});
      return jsonDecode(await store.file.readAsString());
    });
    expect(onDisk['lighting'], {'argbOff': false});
  });

  testWidgets('the notification is localized in English', (tester) async {
    // The preferences provider reads the store on first access, so switching
    // the language here (before the first frame) applies at once.
    await tester.runAsync(
      () => store.saveSection(
        'preferences',
        const Preferences(language: AppLanguage.en).toJson(),
      ),
    );
    await pumpApp(tester);
    await tester.pump();

    store.file.deleteSync();
    Directory('${tmp.path}/config.json').createSync();
    await tester.runAsync(
      () => store
          .saveSection('lighting', {'argbOff': true})
          .catchError((Object _) {}),
    );
    await tester.pump();
    expect(find.textContaining('Could not save your changes'), findsOneWidget);
  });
}
