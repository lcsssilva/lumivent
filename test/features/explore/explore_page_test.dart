import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/core/engine/engine_host.dart';
import 'package:lumivent/core/ui/theme.dart';
import 'package:lumivent/features/explore/presentation/explore_page.dart';
import 'package:lumivent/features/lighting/application/effects_controller.dart';
import 'package:lumivent/features/lighting/application/lighting_controller.dart';
import 'package:lumivent/features/lighting/domain/effect_compat.dart';
import 'package:lumivent/features/lighting/domain/effect_library.dart';
import 'package:lumivent/features/lighting/domain/effect_meta.dart';
import 'package:lumivent/features/lighting/domain/installed_effect.dart';
import 'package:lumivent/features/lighting/domain/lighting_config.dart';

import '../../fakes.dart';

EffectSource _source() =>
    EffectSource(title: 'Teste', properties: [], script: 'var a = 1;');

InstalledEffect _effect(
  String id,
  String title, {
  String? publisher = 'Autor',
  List<String> tags = const [],
  EffectSupport support = EffectSupport.compatible,
  List<EffectIssue> issues = const [],
}) => InstalledEffect(
  id: id,
  title: title,
  publisher: publisher,
  tags: tags,
  source: _source(),
  compatibility: EffectCompatibility(support, issues),
);

class _FakeLibrary implements EffectLibrary {
  _FakeLibrary(this.effects);

  final List<InstalledEffect> effects;
  final removed = <String>[];

  @override
  Future<List<InstalledEffect>> list() async => List.of(effects);

  @override
  Future<InstalledEffect?> find(String id) async =>
      effects.where((e) => e.id == id).firstOrNull;

  @override
  Future<String> readHtml(String id) async => '<html></html>';

  @override
  Future<void> remove(String id) async {
    removed.add(id);
    effects.removeWhere((e) => e.id == id);
  }

  @override
  Future<void> saveThumbnail(String id, Uint8List png) async {}

  @override
  Future<Uint8List?> thumbnail(String id) async => null;
}

class _NoImporter implements EffectImporter {
  @override
  Future<ImportReport> importPaths(List<String> paths) async => ImportReport();

  @override
  Future<ImportReport> importWindowsCache(String folder) async =>
      ImportReport();
}

class _MemoryRepo implements LightingConfigRepository {
  LightingConfig config = LightingConfig();

  @override
  LightingConfig load() => config;

  @override
  Future<void> save(LightingConfig c) async => config = c;
}

void main() {
  late FakeEngine engine;
  late _MemoryRepo repo;
  late _FakeLibrary library;
  late ProviderContainer container;

  setUp(() {
    engine = FakeEngine();
    repo = _MemoryRepo();
    library = _FakeLibrary([
      _effect(
        'rainbow',
        'Rainbow',
        publisher: 'Autor Y',
        tags: const ['Basic', 'Color'],
      ),
      _effect(
        'neon',
        'Neon Shift',
        publisher: 'Outro Autor',
        tags: const ['Advanced'],
        support: EffectSupport.partial,
        issues: const [EffectIssue.audio],
      ),
      _effect(
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
        effectImporterProvider.overrideWithValue(_NoImporter()),
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
        child: MaterialApp(
          theme: buildTheme(),
          home: const Scaffold(body: ExplorePage()),
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
