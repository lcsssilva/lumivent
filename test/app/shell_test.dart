import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/app/app.dart';
import 'package:lumivent/app/desktop/desktop_actions.dart';
import 'package:lumivent/app/navigation/app_route.dart';
import 'package:lumivent/core/engine/engine_host.dart';
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
      name: 'Fans AL V2',
      model: 'Lian Li UNI FAN AL V2',
      status: DeviceStatus.ok,
      detail: 'firmware v0.4 · /dev/hidraw8',
    ),
    DeviceInfo(
      id: 'fury-1',
      kind: DeviceKind.memory,
      name: 'Memória 1',
      model: 'Kingston Fury DDR5',
      status: DeviceStatus.noPermission,
      hint: 'Instale as regras udev.',
    ),
    DeviceInfo(
      id: 'gpu',
      kind: DeviceKind.gpu,
      name: 'Placa de vídeo',
      model: 'Gigabyte RX 9060 XT',
      status: DeviceStatus.unsupported,
    ),
  ],
  conflicts: const ['OpenRGB'],
  scannedAt: DateTime(2026, 10, 18),
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
    engine = FakeEngine();
    autostart = FakeAutostart();
    container = ProviderContainer(
      overrides: [
        engineProvider.overrideWithValue(engine),
        configStoreProvider.overrideWithValue(store),
        ...PreferencesModule.overrides(store),
        ...LightingModule.overrides(store),
        ...FansModule.overrides(store),
        autostartServiceProvider.overrideWithValue(autostart),
        environmentDiagnosticsProvider.overrideWithValue(NoDiagnostics()),
        desktopActionsProvider.overrideWithValue(FakeDesktop()),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    tmp.deleteSync(recursive: true);
  });

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
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
}
