import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/core/engine/isolate_engine.dart';
import 'package:lumivent/features/explore/application/effect_filter.dart';
import 'package:lumivent/features/explore/presentation/view_models/explore_ui_state.dart';
import 'package:lumivent/features/explore/presentation/view_models/explore_view_model.dart';
import 'package:lumivent/features/lighting/domain/effect_import/effect_importer.dart';
import 'package:lumivent/features/lighting/lighting.dart';

import '../../fake_engine.dart';
import 'explore_fixtures.dart';
import 'failing_effect_importer.dart';
import 'fake_effect_library.dart';
import '../../support/memory_lighting_repository.dart';
import 'no_effect_importer.dart';

void main() {
  late FakeEffectLibrary library;
  late ProviderContainer container;

  ProviderContainer containerWith(EffectImporter importer) {
    final c = ProviderContainer(
      overrides: [
        engineProvider.overrideWithValue(FakeEngine()),
        lightingRepositoryProvider.overrideWithValue(
          MemoryLightingRepository(),
        ),
        effectLibraryProvider.overrideWithValue(library),
        effectImporterProvider.overrideWithValue(importer),
      ],
    );
    c.listen(exploreViewModelProvider, (_, _) {});
    return c;
  }

  setUp(() async {
    library = FakeEffectLibrary([
      installedEffect('rainbow', 'Rainbow', tags: const ['Basic']),
      installedEffect('neon', 'Neon Shift', publisher: 'Outro Autor'),
    ]);
    container = containerWith(NoEffectImporter());
    await container.read(installedEffectsProvider.future);
  });
  tearDown(() => container.dispose());

  ExploreViewModel viewModel() =>
      container.read(exploreViewModelProvider.notifier);
  ExploreUiState ui() => container.read(exploreViewModelProvider);
  InstalledEffect effect(String id) =>
      ui().allEffects.firstWhere((e) => e.id == id);

  test('filters combine and survive a library reload', () async {
    viewModel().setTag('Basic');
    viewModel().setQuery('rain');
    expect(ui().visibleEffects.map((e) => e.id), ['rainbow']);
    expect(ui().tags, ['Basic']);

    await viewModel().removeEffect(effect('neon'));
    await container.read(installedEffectsProvider.future);
    expect(ui().filter.tag, 'Basic');
    expect(ui().filter.query, 'rain');
    expect(ui().allEffects.map((e) => e.id), ['rainbow']);

    viewModel().setTag(null);
    viewModel().setSupport(SupportFilter.partial);
    expect(ui().filter.query, 'rain');
    expect(ui().visibleEffects, isEmpty);
  });

  test('applying an effect points the lighting at it', () {
    viewModel().applyEffect(effect('neon'));
    expect(container.read(lightingProvider).effectId, htmlEffectId('neon'));
    expect(ui().isApplied(effect('neon')), isTrue);
  });

  test(
    'removing the applied effect falls back to the default effect',
    () async {
      viewModel().applyEffect(effect('neon'));
      await viewModel().removeEffect(effect('neon'));
      expect(library.removed, ['neon']);
      expect(container.read(lightingProvider).effectId, defaultEffectId);
    },
  );

  test('removing another effect keeps the applied one', () async {
    viewModel().applyEffect(effect('neon'));
    await viewModel().removeEffect(effect('rainbow'));
    expect(container.read(lightingProvider).effectId, htmlEffectId('neon'));
  });

  test('thumbnails are read once until an import replaces them', () async {
    await viewModel().thumbnail(effect('rainbow'));
    await viewModel().thumbnail(effect('rainbow'));
    expect(library.thumbnailReads, 1);

    await viewModel().importPaths(['/tmp/effect.html']);
    await viewModel().thumbnail(effect('rainbow'));
    expect(library.thumbnailReads, 2);
  });

  test('a failed import reaches the caller', () async {
    container.dispose();
    container = containerWith(FailingEffectImporter(StateError('disk')));
    await container.read(installedEffectsProvider.future);
    await expectLater(
      viewModel().importWindowsCache('/mnt/windows'),
      throwsA(isA<StateError>()),
    );
  });
}
