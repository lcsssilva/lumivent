import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/core/engine/engine_host.dart';
import 'package:lumivent/features/lighting/application/installed_effects_controller.dart';
import 'package:lumivent/features/lighting/application/lighting_controller.dart';
import 'package:lumivent/features/lighting/application/lighting_messages.dart';
import 'package:lumivent/features/lighting/application/html_effect_runner.dart';
import 'package:lumivent/features/lighting/domain/effect_compat.dart';
import 'package:lumivent/features/lighting/domain/effect_library.dart';
import 'package:lumivent/features/lighting/domain/effect_meta.dart';
import 'package:lumivent/features/lighting/domain/effect_runtime.dart';
import 'package:lumivent/features/lighting/domain/installed_effect.dart';
import 'package:lumivent/features/lighting/domain/light_device.dart';
import 'package:lumivent/features/lighting/domain/lighting_config.dart';
import 'package:lumivent/features/lighting/domain/rgb.dart';
import 'package:lumivent/features/preferences/application/preferences_controller.dart';
import 'package:lumivent/features/preferences/domain/preferences.dart';

import '../../fakes.dart';

class _Library implements EffectLibrary {
  _Library(this.effect);
  final InstalledEffect effect;

  @override
  Future<List<InstalledEffect>> list() async => [effect];

  @override
  Future<InstalledEffect?> find(String id) async => effect;

  @override
  Future<String> readHtml(String id) async => '<html>effect</html>';

  @override
  Future<void> remove(String id) async {}

  @override
  Future<void> saveThumbnail(String id, Uint8List png) async {}

  @override
  Future<Uint8List?> thumbnail(String id) async => null;
}

class _Repo implements LightingConfigRepository {
  LightingConfig config = LightingConfig(effectId: 'html:test');

  @override
  LightingConfig load() => config;

  @override
  Future<void> save(LightingConfig c) async => config = c;
}

class _Prefs implements PreferencesRepository {
  @override
  Preferences load() => const Preferences();

  @override
  Future<void> save(Preferences preferences) async {}
}

class _FakeRuntime implements EffectRuntime {
  _FakeRuntime(this._frame);

  final EffectFrame _frame;
  final properties = <String, Object?>{};
  final sensors = <String, double>{};
  bool disposed = false;

  @override
  EffectSource get effect =>
      EffectSource(title: 'Teste', properties: const [], script: '');

  @override
  Future<(EffectFrame, Map<LightDeviceId, List<Rgb>>?)> renderSampled(
    double nowMs,
  ) => renderFrame(nowMs).then((frame) => (frame, null));

  @override
  void setSamplePoints(List<(LightDeviceId, int, int)>? points) {}

  @override
  Future<EffectFrame> renderFrame(double nowMs) async => _frame;

  @override
  void setProperty(String name, Object? value) => properties[name] = value;

  @override
  void setSensors(Map<String, double> values) => sensors.addAll(values);

  @override
  Future<Uint8List?> snapshotPng() async => null;

  @override
  List<String> drainLog() => const [];

  @override
  Set<String> get unknownOps => const {};

  @override
  void dispose() => disposed = true;
}

class _Factory implements EffectRuntimeFactory {
  int loads = 0;
  late _FakeRuntime runtime;

  @override
  Future<EffectRuntime> load(
    String html, {
    Map<String, Object?> values = const {},
  }) async {
    loads++;
    final rgba = Uint8List(320 * 200 * 4);
    for (var i = 0; i < rgba.length; i += 4) {
      rgba[i] = 30;
      rgba[i + 1] = 60;
      rgba[i + 2] = 90;
      rgba[i + 3] = 255;
    }
    runtime = _FakeRuntime(EffectFrame(320, 200, rgba));
    return runtime;
  }
}

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
    final repo = _Repo();
    final factory = _Factory();
    final container = ProviderContainer(
      overrides: [
        engineProvider.overrideWithValue(engine),
        lightingRepositoryProvider.overrideWithValue(repo),
        preferencesRepositoryProvider.overrideWithValue(_Prefs()),
        effectLibraryProvider.overrideWithValue(_Library(effect)),
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
}
