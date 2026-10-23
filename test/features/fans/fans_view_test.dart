import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/core/engine/isolate_engine.dart';
import 'package:lumivent/core/persistence/config_store.dart';
import 'package:lumivent/core/ui/theme.dart';
import 'package:lumivent/features/fans/fans.dart';
import 'package:lumivent/features/monitoring/monitoring.dart';
import 'package:lumivent/features/preferences/preferences.dart';

import '../../fake_engine.dart';

import '../../support/app_harness.dart';
import 'memory_fans_repository.dart';

void main() {
  late Directory tmp;
  late FakeEngine engine;
  late MemoryFansRepository repo;
  late ProviderContainer container;

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('lumivent-fans-');
    final store = await ConfigStore.open(tmp);
    engine = FakeEngine();
    repo = MemoryFansRepository();
    container = ProviderContainer(
      overrides: [
        engineProvider.overrideWithValue(engine),
        fansRepositoryProvider.overrideWithValue(repo),
        ...PreferencesModule.overrides(store),
      ],
    );
  });
  tearDown(() {
    container.dispose();
    tmp.deleteSync(recursive: true);
  });

  Future<void> pump(
    WidgetTester tester, {
    Map<String, double> extra = const {},
  }) async {
    tester.view.physicalSize = const Size(1040, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: withPortuguese(
          MaterialApp(
            theme: buildTheme(),
            home: const Scaffold(body: FansView()),
          ),
        ),
      ),
    );
    engine.emit(
      SensorsUpdated(
        SensorSample(DateTime(2026), {
          Metrics.cpuTctl: 60,
          Metrics.alv2Rpm(0): 0,
          Metrics.alv2Rpm(1): 1005,
          ...extra,
        }),
      ),
    );
    await tester.pump();
  }

  FanGroupConfig group1() => container.read(fansProvider)[1];

  testWidgets('renders groups and selects the first one with RPM', (
    tester,
  ) async {
    await pump(tester);
    for (var g = 0; g < fanGroupCount; g++) {
      expect(find.byKey(ValueKey('group-$g')), findsOneWidget);
    }
    expect(find.text('1.005 RPM'), findsWidgets);
    expect(find.text('sem fan'), findsNWidgets(3));
    expect(find.byKey(const ValueKey('fan-curve-editor')), findsOneWidget);
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const ValueKey('preset-standard')))
          .selected,
      isTrue,
    );
  });

  testWidgets('selecting High sends SetFansConfig with the high preset', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('preset-high')));
    await tester.pump();
    final sent = engine.sent.whereType<SetFansConfig>().last;
    expect(sent.config[1].preset, FanPreset.high);
    expect(repo.config[1].preset, FanPreset.high);
  });

  testWidgets('selecting Smooth sends SetFansConfig with the smooth response', (
    tester,
  ) async {
    await pump(tester);
    final seg = find.byKey(const ValueKey('opt-response'));
    await tester.ensureVisible(seg);
    await tester.tap(find.descendant(of: seg, matching: find.text('Suave')));
    await tester.pump();
    expect(
      engine.sent.whereType<SetFansConfig>().last.config[1].response,
      FanResponse.smooth,
    );
    expect(group1().response, FanResponse.smooth);
  });

  testWidgets('available motherboard source appears and can be selected', (
    tester,
  ) async {
    await pump(tester, extra: {'board.vrm': 52});
    final src = find.byKey(const ValueKey('opt-source'));
    await tester.ensureVisible(src);
    await tester.tap(src);
    await tester.pumpAndSettle();
    expect(find.text('Placa-mãe · VRM'), findsOneWidget);
    expect(find.text('Placa-mãe · PCH'), findsNothing);
    await tester.tap(find.text('Placa-mãe · VRM'));
    await tester.pumpAndSettle();
    expect(
      engine.sent.whereType<SetFansConfig>().last.config[1].source,
      FanTempSource.boardVrm,
    );
  });

  testWidgets('unavailable motherboard source is excluded from the list', (
    tester,
  ) async {
    await pump(tester);
    final src = find.byKey(const ValueKey('opt-source'));
    await tester.ensureVisible(src);
    await tester.tap(src);
    await tester.pumpAndSettle();
    expect(find.text('GPU edge'), findsWidgets);
    expect(find.textContaining('Placa-mãe'), findsNothing);
  });

  testWidgets('Start/Stop and Apply to all update the configuration', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('preset-quiet')));
    await tester.pump();
    final startStop = find.byKey(const ValueKey('opt-startstop'));
    await tester.ensureVisible(startStop);
    await tester.tap(startStop);
    await tester.pump();
    expect(group1().startStop, isTrue);

    final apply = find.byKey(const ValueKey('opt-apply-all'));
    await tester.ensureVisible(apply);
    await tester.tap(apply);
    await tester.pump();
    final cfg = engine.sent.whereType<SetFansConfig>().last.config;
    for (final g in cfg.groups) {
      expect(g.preset, FanPreset.quiet);
      expect(g.startStop, isTrue);
    }
  });

  testWidgets('dragging a Standard point changes it to Custom', (tester) async {
    await pump(tester);
    final editor = find.byKey(const ValueKey('fan-curve-editor'));
    await tester.ensureVisible(editor);
    await tester.pump();
    final tl = tester.getTopLeft(editor);
    final size = tester.getSize(editor);
    // Same editor geometry: area from (44, 12) to (w-64, h-28).
    final w = size.width - 64 - 44;
    final h = size.height - 28 - 12;
    final from =
        tl + Offset(44 + .40 * w, 12 + h * (1 - .50)); // point (40 °C, 50 %)
    final saves = repo.saves;
    final gesture = await tester.startGesture(from);
    await gesture.moveBy(const Offset(0, -30));
    await gesture.moveBy(const Offset(0, -30));
    await tester.pump();
    expect(group1().preset, FanPreset.custom);
    expect(repo.saves, saves, reason: 'do not save while dragging');
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 500)); // double-click timer
    final p = group1().points[1];
    expect(p.temp, 40);
    expect(p.percent, greaterThan(60));
    expect(group1().points.length, 5);
    expect(repo.saves, saves + 1);
    expect(repo.config[1].preset, FanPreset.custom);
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const ValueKey('preset-custom')))
          .selected,
      isTrue,
    );
  });
}
