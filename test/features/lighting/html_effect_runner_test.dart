import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/core/engine/isolate_engine.dart';
import 'package:lumivent/features/lighting/application/effects/installed_effects_notifier.dart';
import 'package:lumivent/features/lighting/application/lighting_notifier.dart';
import 'package:lumivent/features/lighting/application/messages/set_html_effect_frame.dart';
import 'package:lumivent/features/lighting/application/effects/html_effect_runner.dart';
import 'package:lumivent/features/lighting/application/effects/html_effect_status.dart';
import 'package:lumivent/features/lighting/domain/effects/effect_compatibility.dart';
import 'package:lumivent/features/lighting/domain/effects/effect_source.dart';
import 'package:lumivent/features/lighting/domain/effects/installed_effect.dart';
import 'package:lumivent/features/lighting/domain/light_device.dart';
import 'package:lumivent/features/lighting/domain/config/lighting_config.dart';
import 'package:lumivent/features/lighting/domain/rgb.dart';
import 'package:lumivent/features/preferences/application/preferences_notifier.dart';

import '../../fake_engine.dart';
import '../../support/memory_preferences_repository.dart';
import 'fake_runtime_factory.dart';
import 'runner_effect_library.dart';
import 'runner_lighting_repository.dart';

void main() {
  testWidgets('renders the installed effect and sends sampled colors', (
    tester,
  ) async {
    final engine = FakeEngine();
    final effect = InstalledEffect(
      id: 'test',
      title: 'Teste',
      source: EffectSource(
        title: 'Teste',
        properties: const [],
        script: 'var a = 1;',
      ),
      compatibility: const EffectCompatibility(EffectSupport.compatible, []),
    );
    final repo = RunnerLightingRepository();
    final factory = FakeRuntimeFactory();
    final container = ProviderContainer(
      overrides: [
        engineProvider.overrideWithValue(engine),
        lightingRepositoryProvider.overrideWithValue(repo),
        preferencesRepositoryProvider.overrideWithValue(
          MemoryPreferencesRepository(),
        ),
        effectLibraryProvider.overrideWithValue(RunnerEffectLibrary(effect)),
        effectRuntimeFactoryProvider.overrideWithValue(factory),
      ],
    );
    var disposed = false;
    addTearDown(() {
      if (!disposed) container.dispose();
    });
    container.listen(htmlEffectRunnerProvider, (_, _) {});

    // Let _open() finish reading the library and loading the runtime.
    await tester.pump();
    await tester.pump();
    expect(factory.loads, 1);
    expect(container.read(htmlEffectRunnerProvider).running, isTrue);

    await tester.pump(const Duration(milliseconds: 40));
    await tester.pump();
    final sent = engine.sent.whereType<SetHtmlEffectFrame>().toList();
    expect(sent, isNotEmpty);
    expect(sent.last.effectId, 'html:test');
    expect(
      sent.last.pixels[LightDeviceId.chassis]!.first,
      const Rgb(30, 60, 90),
    );
    expect(container.read(htmlEffectFramesProvider).value, isNotNull);

    // A control change reaches the JS runtime on the next tick.
    container
        .read(lightingProvider.notifier)
        .update((c) => c.withEffectValue('html:test', 'speed', 80));
    await tester.pump(const Duration(milliseconds: 40));
    await tester.pump();
    expect(factory.runtime.properties['speed'], 80);

    // Let the debounced lighting save finish, then stop the periodic renderer
    // inside the test body (Flutter checks for pending timers before teardown).
    await tester.pump(const Duration(seconds: 1));
    container.dispose();
    disposed = true;
    expect(factory.runtime.disposed, isTrue);
  });

  testWidgets('asks for the frame pixels only for the thumbnail and preview', (
    tester,
  ) async {
    final engine = FakeEngine();
    final effect = InstalledEffect(
      id: 'test',
      title: 'Teste',
      source: EffectSource(title: 'Teste', properties: const [], script: ''),
      compatibility: const EffectCompatibility(EffectSupport.compatible, []),
    );
    const sampled = {
      LightDeviceId.ram1: [Rgb(1, 2, 3)],
    };
    final factory = FakeRuntimeFactory(colors: sampled);
    final container = ProviderContainer(
      overrides: [
        engineProvider.overrideWithValue(engine),
        lightingRepositoryProvider.overrideWithValue(
          RunnerLightingRepository(),
        ),
        preferencesRepositoryProvider.overrideWithValue(
          MemoryPreferencesRepository(),
        ),
        effectLibraryProvider.overrideWithValue(RunnerEffectLibrary(effect)),
        effectRuntimeFactoryProvider.overrideWithValue(factory),
      ],
    );
    container.listen(htmlEffectRunnerProvider, (_, _) {});
    await tester.pump();
    await tester.pump();

    Future<void> tick() async {
      await tester.pump(const Duration(milliseconds: 40));
      await tester.pump();
    }

    // The first frame feeds the thumbnail; with no preview listening, the
    // next ones carry only the colors.
    await tick();
    await tick();
    expect(factory.runtime.frameRequests.take(2), [true, false]);
    expect(engine.sent.whereType<SetHtmlEffectFrame>().last.pixels, sampled);

    final feed = container.read(htmlEffectFramesProvider);
    void preview() {}
    feed.addListener(preview);
    factory.runtime.frameRequests.clear();
    await tick();
    expect(factory.runtime.frameRequests, isNotEmpty);
    expect(factory.runtime.frameRequests, everyElement(isTrue));

    feed.removeListener(preview);
    container.dispose();
  });

  test('paused is derived from the issue and carries the slow frame time', () {
    const loading = HtmlEffectStatus(effectId: 'html:test');
    expect(loading.running, isTrue);
    expect(loading.paused, isFalse);

    final paused = loading.copyWith(
      issue: HtmlEffectIssue.paused,
      slowFrameMs: 310,
    );
    expect(paused.paused, isTrue);
    expect(paused.running, isFalse);
    expect(paused.slowFrameMs, 310);
  });
}
