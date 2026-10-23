import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/app/config_transfer.dart';
import 'package:lumivent/core/engine/isolate_engine.dart';
import 'package:lumivent/core/i18n/app_strings.dart';
import 'package:lumivent/core/persistence/config_store.dart';
import 'package:lumivent/features/fans/fans.dart';
import 'package:lumivent/features/lighting/infrastructure/lighting_codec.dart';
import 'package:lumivent/features/lighting/lighting.dart';
import 'package:lumivent/features/preferences/infrastructure/preferences_codec.dart';
import 'package:lumivent/features/preferences/preferences.dart';

import '../fake_engine.dart';

void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('lumivent-transfer-'));
  tearDown(() => tmp.deleteSync(recursive: true));

  Future<ConfigStore> store(String name) =>
      ConfigStore.open(Directory('${tmp.path}/$name'));

  test('export then import carries every module section', () async {
    final a = await store('a');
    await a.saveSection('preferences', {'effectsFps': 15});
    await a.saveSection('lighting', {'argbOff': true});
    await a.saveSection('fans', {'groups': []});

    final b = await store('b');
    await b.saveSection('lighting', {'argbOff': false});
    final imported = await importConfig(b, exportConfig(a));

    expect(imported, ['preferences', 'lighting', 'fans']);
    expect(b.section('lighting'), {'argbOff': true});
    expect(b.section('preferences'), {'effectsFps': 15});
    final onDisk = jsonDecode(b.file.readAsStringSync());
    expect(onDisk['lighting'], {'argbOff': true});
    // The previous file is kept next to it.
    final backup = File('${b.file.path}.$importBackupSuffix');
    expect(jsonDecode(backup.readAsStringSync())['lighting'], {
      'argbOff': false,
    });
  });

  test(
    'coordinator applies an import and reloads the imported modules',
    () async {
      final s = await store('coordinator');
      final engine = FakeEngine();
      final container = ProviderContainer(
        overrides: [
          configStoreProvider.overrideWithValue(s),
          engineProvider.overrideWithValue(engine),
          ...PreferencesModule.overrides(s),
          ...LightingModule.overrides(s),
          ...FansModule.overrides(s),
        ],
      );
      addTearDown(container.dispose);

      final exported = await store('coordinator-exported');
      await exported.saveSection(
        'preferences',
        encodePreferences(const Preferences(effectsFps: 15)),
      );
      await exported.saveSection(
        'lighting',
        encodeLightingConfig(LightingConfig(argbOff: true)),
      );

      final transfer = container.read(configTransferProvider);
      final sections = await transfer.importText(exportConfig(exported));

      expect(sections, ['preferences', 'lighting']);
      expect(container.read(preferencesProvider).effectsFps, 15);
      expect(container.read(lightingProvider).argbOff, isTrue);
      expect(
        engine.sent.whereType<SetLightingConfig>().last.config.argbOff,
        isTrue,
      );
      expect(transfer.backupPath, endsWith('.before-import'));
    },
  );

  test('unknown sections are ignored, missing ones are kept', () async {
    final s = await store('s');
    await s.saveSection('fans', {'keep': 1});
    await importConfig(
      s,
      jsonEncode({
        'version': 1,
        'lighting': {'argbOff': true},
        'other': {'x': 1},
      }),
    );
    expect(s.section('fans'), {'keep': 1});
    expect(s.section('other'), isEmpty);
  });

  test('invalid files are rejected with a message for the user', () {
    void rejects(String text, String message) => expect(
      () => importableSections(text, strings: AppStrings.pt),
      throwsA(
        isA<FormatException>().having((e) => e.message, 'message', message),
      ),
    );
    rejects('{', 'O arquivo não é um JSON válido.');
    rejects('[1]', 'O arquivo não é uma configuração do app.');
    rejects(
      jsonEncode({'version': ConfigStore.schemaVersion + 1, 'fans': {}}),
      'O arquivo veio de uma versão mais nova do app.',
    );
    rejects(
      jsonEncode({'version': 1, 'lighting': 'x'}),
      'O arquivo não tem preferências, iluminação nem fans.',
    );
  });

  test('reload applies the imported config and resends it', () async {
    final s = await store('live');
    final engine = FakeEngine();
    final container = ProviderContainer(
      overrides: [
        engineProvider.overrideWithValue(engine),
        ...PreferencesModule.overrides(s),
        ...LightingModule.overrides(s),
        ...FansModule.overrides(s),
      ],
    );
    addTearDown(container.dispose);
    expect(container.read(lightingProvider).argbOff, isFalse);
    final fanNames = [
      for (final g in container.read(fansProvider).groups) g.name,
    ];

    final exported = await store('exported');
    await exported.saveSection(
      'lighting',
      encodeLightingConfig(LightingConfig(argbOff: true)),
    );
    await importConfig(s, exportConfig(exported));
    container.read(lightingProvider.notifier).reload();
    container.read(fansProvider.notifier).reload();

    expect(container.read(lightingProvider).argbOff, isTrue);
    expect(
      engine.sent.whereType<SetLightingConfig>().last.config.argbOff,
      isTrue,
    );
    // Fans had no section in the file: reloaded unchanged, still resent.
    expect([
      for (final g in container.read(fansProvider).groups) g.name,
    ], fanNames);
    expect(engine.sent.whereType<SetFansConfig>(), hasLength(1));
  });

  group('reading an import file', () {
    Stream<List<int>> chunks(List<List<int>> parts) =>
        Stream.fromIterable(parts);

    test('valid UTF-8 is returned as text', () async {
      expect(
        await readImportText(
          chunks([utf8.encode('{"a":'), utf8.encode('"é"}')]),
        ),
        '{"a":"é"}',
      );
    });

    test('a file over the limit is rejected before it is read whole', () async {
      final chunk = List<int>.filled(1024 * 1024, 0x20);
      var pulled = 0;
      final endless = Stream<List<int>>.periodic(Duration.zero, (_) {
        pulled++;
        return chunk;
      });
      await expectLater(
        readImportText(endless, strings: AppStrings.pt),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            AppStrings.pt.shell.fileTooLarge(maxImportMegabytes),
          ),
        ),
      );
      expect(pulled, maxImportMegabytes + 1);
    });

    test('malformed UTF-8 gets the localized message', () async {
      await expectLater(
        readImportText(
          chunks([
            [0x7B, 0xC3, 0x28, 0x7D],
          ]),
          strings: AppStrings.pt,
        ),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            AppStrings.pt.shell.invalidJson,
          ),
        ),
      );
    });
  });
}
