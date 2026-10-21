import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/core/persistence/config_store.dart';

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
