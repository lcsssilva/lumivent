import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/core/persistence/config_store.dart';
import 'package:lumivent/core/persistence/config_write_failure.dart';

void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('lumivent-config-'));
  tearDown(() => tmp.deleteSync(recursive: true));

  test('missing file returns empty sections', () async {
    final store = await ConfigStore.open(Directory('${tmp.path}/nao-existe'));
    expect(store.section('lighting'), isEmpty);
  });

  test(
    'each module writes only its section; the file keeps all sections',
    () async {
      final dir = Directory('${tmp.path}/lumivent');
      final store = await ConfigStore.open(dir);
      await store.saveSection('preferences', {'effectsFps': 60});
      await store.saveSection('lighting', {'argbOff': true});
      await store.saveSection('preferences', {'effectsFps': 15});

      final json = jsonDecode(store.file.readAsStringSync());
      expect(json, {
        'version': ConfigStore.schemaVersion,
        'preferences': {'effectsFps': 15},
        'lighting': {'argbOff': true},
      });
      expect(File('${store.file.path}.tmp').existsSync(), isFalse);

      final reopened = await ConfigStore.open(dir);
      expect(reopened.section('lighting'), {'argbOff': true});
    },
  );

  test(
    'returned section is a copy: changing it does not change the store',
    () async {
      final store = await ConfigStore.open(tmp);
      await store.saveSection('a', {'x': 1});
      store.section('a')['x'] = 2;
      expect(store.section('a'), {'x': 1});
    },
  );

  test('a failed write throws the write failure, mutates the section in memory '
      'and reports exactly once at flush while it stays unrecovered', () async {
    final blocked = File('${tmp.path}/blocked')
      ..writeAsStringSync('not a directory');
    final store = await ConfigStore.open(Directory(blocked.path));

    final failures = <ConfigWriteFailure>[];
    store.writeFailures.listen(failures.add);

    await expectLater(
      store.saveSection('preferences', {'effectsFps': 60}),
      throwsA(
        isA<ConfigWriteFailure>().having(
          (f) => f.cause,
          'cause',
          isA<FileSystemException>(),
        ),
      ),
    );
    // The observer sees the failure without depending on flush().
    expect(failures, hasLength(1));

    await expectLater(store.flush(), throwsA(isA<ConfigWriteFailure>()));
    // Reported exactly once.
    await expectLater(store.flush(), completes);
  });

  test('a later successful write recovers the failed change', () async {
    final blocked = File('${tmp.path}/blocked')
      ..writeAsStringSync('not a directory');
    final store = await ConfigStore.open(Directory(blocked.path));

    await expectLater(
      store.saveSection('preferences', {'effectsFps': 60}),
      throwsA(isA<ConfigWriteFailure>()),
    );

    blocked.deleteSync();
    Directory(blocked.path).createSync();
    await store.saveSection('preferences', {'effectsFps': 30});
    // The successful write already includes the failed change (the snapshot
    // is the whole file), so there is nothing left to report at flush.
    expect(store.section('preferences'), {'effectsFps': 30});
    await store.flush();
  });

  test('a failed import restores the previous sections in memory', () async {
    final blocked = File('${tmp.path}/blocked')
      ..writeAsStringSync('not a directory');
    final store = await ConfigStore.open(Directory(blocked.path));
    await expectLater(
      store.saveSection('lighting', {'argbOff': false}),
      throwsA(isA<ConfigWriteFailure>()),
    );

    await expectLater(
      store.replaceSections({
        'lighting': {'argbOff': true},
        'fans': {'curve': 'silent'},
      }, backupSuffix: 'before-import'),
      throwsA(isA<ConfigWriteFailure>()),
    );

    expect(store.section('lighting'), {'argbOff': false});
    expect(store.section('fans'), isEmpty);

    // The next successful section save does not carry the failed import.
    blocked.deleteSync();
    Directory(blocked.path).createSync();
    await store.saveSection('preferences', {'effectsFps': 30});
    expect(jsonDecode(store.file.readAsStringSync()), {
      'version': ConfigStore.schemaVersion,
      'lighting': {'argbOff': false},
      'preferences': {'effectsFps': 30},
    });
  });

  test('consecutive failures are each notified as a new event', () async {
    final blocked = File('${tmp.path}/blocked')
      ..writeAsStringSync('not a directory');
    final store = await ConfigStore.open(Directory(blocked.path));

    final failures = <ConfigWriteFailure>[];
    store.writeFailures.listen(failures.add);

    await expectLater(
      store.saveSection('preferences', {'effectsFps': 60}),
      throwsA(isA<ConfigWriteFailure>()),
    );
    await expectLater(
      store.saveSection('lighting', {'argbOff': true}),
      throwsA(isA<ConfigWriteFailure>()),
    );
    await expectLater(store.flush(), throwsA(isA<ConfigWriteFailure>()));

    expect(failures.map((failure) => failure.section), [
      'preferences',
      'lighting',
    ]);
  });

  test('the message names the section or the whole configuration', () async {
    final blocked = File('${tmp.path}/blocked')
      ..writeAsStringSync('not a directory');
    final store = await ConfigStore.open(Directory(blocked.path));

    await expectLater(
      store.saveSection('preferences', {'effectsFps': 60}),
      throwsA(
        isA<ConfigWriteFailure>()
            .having((f) => f.section, 'section', 'preferences')
            .having(
              (f) => f.toString(),
              'toString()',
              startsWith('Failed to save preferences'),
            ),
      ),
    );

    await expectLater(
      store.replaceSections({
        'lighting': {'argbOff': true},
      }),
      throwsA(
        isA<ConfigWriteFailure>()
            .having((f) => f.section, 'section', 'configuration')
            .having(
              (f) => f.toString(),
              'toString()',
              startsWith('Failed to save configuration:'),
            ),
      ),
    );
  });

  test('corrupted file becomes .bad and the store starts empty', () async {
    File('${tmp.path}/config.json').writeAsStringSync('{ this is not json');
    final store = await ConfigStore.open(tmp);
    expect(store.section('preferences'), isEmpty);
    expect(File('${tmp.path}/config.json.bad').existsSync(), isTrue);
  });

  test('XDG_CONFIG_HOME takes precedence over ~/.config', () {
    expect(
      defaultConfigDir({'HOME': '/home/u'}).path,
      '/home/u/.config/lumivent',
    );
    expect(
      defaultConfigDir({'HOME': '/home/u', 'XDG_CONFIG_HOME': '/x'}).path,
      '/x/lumivent',
    );
  });
}
