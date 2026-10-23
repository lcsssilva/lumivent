import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/core/engine/isolate_engine.dart';
import 'package:lumivent/core/ui/theme.dart';
import 'package:lumivent/features/explore/presentation/views/explore_view.dart';
import 'package:lumivent/features/lighting/application/effects/installed_effects_notifier.dart';
import 'package:lumivent/features/lighting/application/lighting_notifier.dart';
import 'package:lumivent/features/lighting/domain/effects/effect_compatibility.dart';
import 'package:lumivent/features/lighting/domain/effects/installed_effect.dart';

import '../../fake_engine.dart';

import '../../support/app_harness.dart';
import 'explore_fixtures.dart';
import 'fake_effect_library.dart';
import '../../support/memory_lighting_repository.dart';
import 'no_effect_importer.dart';

void main() {
  late FakeEngine engine;
  late MemoryLightingRepository repo;
  late FakeEffectLibrary library;
  late ProviderContainer container;

  setUp(() {
    engine = FakeEngine();
    repo = MemoryLightingRepository();
    library = FakeEffectLibrary([
      installedEffect(
        'rainbow',
        'Rainbow',
        publisher: 'Autor Y',
        tags: const ['Basic', 'Color'],
      ),
      installedEffect(
        'neon',
        'Neon Shift',
        publisher: 'Outro Autor',
        tags: const ['Advanced'],
        support: EffectSupport.partial,
        issues: const [EffectIssue.audio],
      ),
      installedEffect(
        'screen',
        'Screen Capture',
        support: EffectSupport.unsupported,
        issues: const [EffectIssue.capture],
      ),
    ]);
    container = ProviderContainer(
      overrides: [
        engineProvider.overrideWithValue(engine),
        lightingRepositoryProvider.overrideWithValue(repo),
        effectLibraryProvider.overrideWithValue(library),
        effectImporterProvider.overrideWithValue(NoEffectImporter()),
      ],
    );
  });

  tearDown(() => container.dispose());

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: withPortuguese(
          MaterialApp(
            theme: buildTheme(),
            home: const Scaffold(body: ExploreView()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists installed effects with badges and filters them', (
    tester,
  ) async {
    await pump(tester);
    expect(find.byKey(const ValueKey('effect-card-rainbow')), findsOneWidget);
    expect(find.byKey(const ValueKey('effect-card-neon')), findsOneWidget);
    expect(find.byKey(const ValueKey('effect-card-screen')), findsOneWidget);
    expect(find.text('Compatível'), findsOneWidget);
    expect(find.text('Parcial'), findsOneWidget);
    expect(find.text('Não suportado'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('explore-search')), 'neon');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('effect-card-neon')), findsOneWidget);
    expect(find.byKey(const ValueKey('effect-card-rainbow')), findsNothing);

    await tester.enterText(find.byKey(const Key('explore-search')), '');
    await tester.tap(find.byKey(const ValueKey('filter-partial')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('effect-card-neon')), findsOneWidget);
    expect(find.byKey(const ValueKey('effect-card-rainbow')), findsNothing);
  });

  testWidgets('applies a compatible effect and disables unsupported ones', (
    tester,
  ) async {
    await pump(tester);
    final card = find.byKey(const ValueKey('effect-card-rainbow'));
    await tester.tap(find.descendant(of: card, matching: find.text('Aplicar')));
    await tester.pumpAndSettle();
    expect(container.read(lightingProvider).effectId, htmlEffectId('rainbow'));

    final unsupported = find.byKey(const ValueKey('effect-card-screen'));
    final button = find.descendant(
      of: unsupported,
      matching: find.byType(FilledButton),
    );
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    expect(
      find.descendant(
        of: unsupported,
        matching: find.textContaining('captura de tela'),
      ),
      findsOneWidget,
    );
    // Let the debounced lighting save and the snackbar timer finish.
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('removes an effect after confirmation', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('remove-neon')));
    await tester.pumpAndSettle();
    expect(find.text('Remover “Neon Shift”?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Remover'));
    await tester.pumpAndSettle();
    expect(library.removed, ['neon']);
    expect(find.byKey(const ValueKey('effect-card-neon')), findsNothing);
    expect(find.text('“Neon Shift” removido.'), findsOneWidget);
  });
}
