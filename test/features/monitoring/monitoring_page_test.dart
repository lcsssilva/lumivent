import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/core/engine/engine_host.dart';
import 'package:lumivent/core/persistence/config_store.dart';
import 'package:lumivent/core/ui/theme.dart';
import 'package:lumivent/features/monitoring/infrastructure/nvme.dart';
import 'package:lumivent/features/monitoring/monitoring.dart';
import 'package:lumivent/features/preferences/preferences.dart';

import '../../fakes.dart';
import 'smart_fixture.dart';

void main() {
  late Directory tmp;
  late FakeEngine engine;
  late ProviderContainer container;

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('lumivent-mon-');
    final store = await ConfigStore.open(tmp);
    engine = FakeEngine();
    container = ProviderContainer(
      overrides: [
        engineProvider.overrideWithValue(engine),
        ...PreferencesModule.overrides(store),
      ],
    );
  });
  tearDown(() {
    container.dispose();
    tmp.deleteSync(recursive: true);
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1300, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildTheme(),
          home: const Scaffold(body: MonitoringPage()),
        ),
      ),
    );
  }

  testWidgets('cards, SSD health, and SMART table', (tester) async {
    await pump(tester);
    expect(find.text('Lendo SSDs…'), findsOneWidget);

    engine.emit(
      SensorsUpdated(
        SensorSample(DateTime(2026), {
          Metrics.cpuTctl: 52.4,
          Metrics.cpuClock: 4912,
          Metrics.gpuEdge: 44,
          Metrics.gpuJunction: 47,
          Metrics.gpuFan: 0,
          Metrics.memUsed: 9.1 * (1 << 30),
          Metrics.memTotal: 32.0 * (1 << 30),
          'board.vrm': 48,
          'board.fan.cpu': 2721,
          'board.fan.sys1': 0,
          Metrics.alv2Rpm(0): 0,
          Metrics.alv2Rpm(1): 1005,
          Metrics.ssdTemp('nvme0'): 41,
        }),
      ),
    );
    final log = parseNvmeSmartLog(smartLogBytes())!;
    engine.emit(
      SsdsUpdated([
        SsdInfo(
          controller: 'nvme0',
          model: 'KINGSTON SFYRS1000G',
          serial: 'S1',
          firmware: 'EIFK31.6',
          capacityBytes: 1000204886016,
          smart: log,
        ),
        const SsdInfo(
          controller: 'nvme1',
          model: 'KINGSTON SNV3S1000G',
          serial: 'S2',
          firmware: 'ERFK1N.3',
          smartError: SsdSmartError(SsdErrorKind.helperMissing),
        ),
      ], DateTime(2026)),
    );
    await tester.pump();

    expect(find.text('52 °C'), findsOneWidget);
    // GPU: junction headline, zero-fan instead of a bare 0 rpm.
    expect(find.text('47 °C'), findsOneWidget);
    expect(find.text('junction'), findsOneWidget);
    expect(find.text('parado (zero-fan)'), findsOneWidget);
    expect(find.text('4,91 GHz'), findsOneWidget);
    expect(find.text('9,1 GiB'), findsOneWidget);
    expect(find.text('VRM MOS'), findsOneWidget);
    expect(find.text('Bomba (CPU_FAN)'), findsOneWidget);
    expect(
      find.text('System 1'),
      findsNothing,
      reason: 'connector without RPM is hidden',
    );
    expect(find.text('Grupo 1'), findsOneWidget);
    expect(find.text('Grupo 0'), findsNothing, reason: 'group 0 is empty');
    expect(find.text('1.005 rpm'), findsOneWidget);

    expect(find.text('Boa'), findsOneWidget);
    expect(find.text('98 %'), findsOneWidget);
    expect(find.text('12,4 TB'), findsWidgets);
    expect(find.text('1.820 h'), findsOneWidget);
    expect(find.text('Sem SMART'), findsOneWidget);
    expect(find.textContaining('pacote lumivent'), findsOneWidget);

    await tester.tap(find.text('Detalhes').first);
    await tester.pumpAndSettle();
    expect(find.text('Percentual usado'), findsOneWidget);
    expect(find.text('Sensor de temperatura 2'), findsOneWidget);
    await tester.tap(find.text('Fechar'));
    await tester.pumpAndSettle();

    expect(
      find.text('atualiza a cada minuto · lido às 00:00:00'),
      findsOneWidget,
    );

    container
        .read(preferencesProvider.notifier)
        .change((p) => p.copyWith(temperatureUnit: TemperatureUnit.fahrenheit));
    await tester.pump();
    expect(find.text('126 °F'), findsOneWidget);
  });
}
