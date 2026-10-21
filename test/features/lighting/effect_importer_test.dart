import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/lighting/domain/effect_compat.dart';
import 'package:lumivent/features/lighting/domain/effect_library.dart';
import 'package:lumivent/features/lighting/domain/installed_effect.dart';
import 'package:lumivent/features/lighting/infrastructure/effect_importer.dart';
import 'package:lumivent/features/lighting/infrastructure/effect_library.dart';

String effectHtml(
  String title, {
  String publisher = 'Teste',
  String script = 'var n = 0; function loop(){ n++; }',
}) =>
    '''
<!doctype html>
<html>
<head>
  <title>$title</title>
  <meta publisher="$publisher" />
  <meta property="speed" label="Speed" type="number" min="0" max="100" default="50" />
</head>
<body><canvas id="exCanvas" width="320" height="200"></canvas></body>
<script>$script</script>
</html>
''';

void main() {
  late Directory temp;
  late FileEffectLibrary library;
  late FileEffectImporter importer;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('lumivent-effects-test-');
    library = FileEffectLibrary(Directory('${temp.path}/effects'));
    importer = FileEffectImporter(library);
  });

  tearDown(() {
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });

  test('imports an HTML file using the title as id', () async {
    final file = File('${temp.path}/rainbow.html')
      ..writeAsStringSync(effectHtml('Rainbow Test'));
    final report = await importer.importPaths([file.path]);
    expect(report.imported, 1);
    expect(report.issues, isEmpty);

    final effects = await library.list();
    expect(effects.single.id, 'rainbow');
    expect(effects.single.title, 'Rainbow Test');
    expect(effects.single.publisher, 'Teste');
    expect(effects.single.origin, EffectOrigin.file);
    expect(effects.single.importedAt, isNotNull);
    expect(effects.single.compatibility.support, EffectSupport.compatible);
    expect(await library.readHtml('rainbow'), contains('Rainbow Test'));
    expect(
      File('${temp.path}/effects/rainbow/effect.json').existsSync(),
      isTrue,
    );
  });

  test('imports malformed UTF-8 with replacement characters', () async {
    final bytes = Uint8List.fromList(effectHtml('Rainbow').codeUnits);
    final title = bytes.indexOf('Rainbow'.codeUnits.first);
    bytes[title] = 0xff;
    final file = File('${temp.path}/rainbow.html')..writeAsBytesSync(bytes);

    final report = await importer.importPaths([file.path]);

    expect(report.imported, 1);
    expect(report.issues, isEmpty);
    expect(await library.readHtml('rainbow'), contains('\uFFFD'));
  });

  test('rejects an HTML file larger than the import limit', () async {
    final file = File('${temp.path}/large.html')
      ..writeAsBytesSync(Uint8List(4 * 1024 * 1024 + 1));

    final report = await importer.importPaths([file.path]);

    expect(report.imported, 0);
    expect(report.issues, hasLength(1));
    expect(report.issues.single.detail, contains('import limit'));
  });

  test('re-importing replaces the effect instead of duplicating it', () async {
    final file = File('${temp.path}/rainbow.html')
      ..writeAsStringSync(effectHtml('Rainbow'));
    await importer.importPaths([file.path]);
    final again = await importer.importPaths([file.path]);
    expect(again.imported, 0);
    expect(again.replaced, 1);
    expect(await library.list(), hasLength(1));
  });

  test(
    'imports every effect.html in a folder and names it by the folder',
    () async {
      final root = Directory('${temp.path}/pack')..createSync();
      for (final name in ['Neon', 'Liquid']) {
        final dir = Directory('${root.path}/$name')..createSync();
        File('${dir.path}/effect.html')
            .writeAsStringSync(effectHtml('$name Shift'));
      }
      final report = await importer.importPaths([root.path]);
      expect(report.imported, 2);
      final ids = (await library.list()).map((e) => e.id).toSet();
      expect(ids, {'neon', 'liquid'});
      final neon = await library.find('neon');
      expect(neon!.origin, EffectOrigin.folder);
      expect(neon.title, 'Neon Shift');
    },
  );

  test('imports a folder that is itself one effect', () async {
    final dir = Directory('${temp.path}/My Cool Effect')..createSync();
    File('${dir.path}/effect.html').writeAsStringSync(effectHtml('Ignored'));
    final report = await importer.importPaths([dir.path]);
    expect(report.imported, 1);
    final effect = (await library.list()).single;
    expect(effect.id, 'my-cool-effect');
    expect(effect.title, 'Ignored');
  });

  test('imports a ZIP with a folder per effect', () async {
    final archive = Archive()
      ..add(ArchiveFile.string('Neon/effect.html', effectHtml('Neon Shift')))
      ..add(ArchiveFile.string('Neon/readme.txt', 'oi'))
      ..add(
        ArchiveFile.string(
          'Liquid/effect.html',
          effectHtml('Liquid', publisher: 'Outro'),
        ),
      );
    final zip = File('${temp.path}/pack.zip')
      ..writeAsBytesSync(ZipEncoder().encodeBytes(archive));

    final report = await importer.importPaths([zip.path]);
    expect(report.imported, 2);
    expect(report.issues, isEmpty);
    final effects = await library.list();
    expect(effects.map((e) => e.id).toSet(), {'neon', 'liquid'});
    expect(effects.every((e) => e.origin == EffectOrigin.zip), isTrue);
  });

  test(
    'imports a ZIP with effect.html at the root using the ZIP name',
    () async {
      final archive = Archive()
        ..add(ArchiveFile.string('effect.html', effectHtml('Root Effect')));
      final zip = File('${temp.path}/MyPack.zip')
        ..writeAsBytesSync(ZipEncoder().encodeBytes(archive));
      await importer.importPaths([zip.path]);
      expect((await library.list()).single.id, 'mypack');
    },
  );

  test('skips ZIP entries whose uncompressed HTML exceeds the limit', () async {
    final html = Uint8List(4 * 1024 * 1024 + 1);
    final archive = Archive()
      ..add(ArchiveFile('Big/effect.html', html.length, html));
    final zip = File('${temp.path}/large.zip')
      ..writeAsBytesSync(ZipEncoder().encodeBytes(archive));

    final report = await importer.importPaths([zip.path]);

    expect(report.imported, 0);
    expect(report.issues, hasLength(1));
    expect(report.issues.single.detail, contains('size limit'));
  });

  test(
    'reports invalid paths and unsafe ZIP entries without aborting',
    () async {
      final archive = Archive()
        ..add(ArchiveFile.string('../evil.html', effectHtml('Evil')))
        ..add(ArchiveFile.string('Good/effect.html', effectHtml('Good')));
      final zip = File('${temp.path}/mix.zip')
        ..writeAsBytesSync(ZipEncoder().encodeBytes(archive));
      final report = await importer.importPaths([
        zip.path,
        '${temp.path}/nao-existe.html',
      ]);
      expect(report.imported, 1);
      expect(report.issues, hasLength(1));
      expect((await library.list()).single.id, 'good');
    },
  );

  test('imports a Windows cache with catalog names and tags', () async {
    final cache = Directory('${temp.path}/win/EffectsApp/cache')
      ..createSync(recursive: true);
    final effects = Directory('${cache.path}/effects')..createSync();
    Directory('${effects.path}/rainbow').createSync();
    File('${effects.path}/rainbow/effect.html')
        .writeAsStringSync(effectHtml('Rainbow', publisher: 'Autor Y'));

    Directory('${effects.path}/audio-bars').createSync();
    File('${effects.path}/audio-bars/effect.html').writeAsStringSync(
      effectHtml('Audio Bars', script: 'if (engine.audio.level > -40) { }'),
    );

    Directory('${effects.path}/screen').createSync();
    File('${effects.path}/screen/effect.html')
        .writeAsStringSync(effectHtml('Screen', script: 'engine.zone.hue[0];'));

    File('${cache.path}/catalog_en.json').writeAsStringSync('''
[
  {
    "id": "rainbow",
    "name": "Rainbow SR",
    "publisher": "Autor Y",
    "description": "Cores girando.",
    "type": "Basic",
    "tags": ["Color"],
    "requires_pro": false
  },
  {
    "id": "audio-bars",
    "name": "Audio Bars SR",
    "publisher": "Autor Y",
    "type": "Audio",
    "tags": [],
    "requires_pro": false
  }
]
''');

    final report = await importer.importWindowsCache(cache.path);
    expect(report.catalogFound, isTrue);
    expect(report.imported, 3);
    expect(report.issues, isEmpty);

    final rainbow = await library.find('rainbow');
    expect(rainbow!.title, 'Rainbow SR');
    expect(rainbow.description, 'Cores girando.');
    expect(rainbow.tags, containsAll(['Basic', 'Color']));
    expect(rainbow.origin, EffectOrigin.windowsCache);

    final audio = await library.find('audio-bars');
    expect(audio!.compatibility.support, EffectSupport.partial);
    expect(audio.tags, contains('Audio'));

    final screen = await library.find('screen');
    expect(screen!.compatibility.support, EffectSupport.unsupported);
  });

  test('accepts the parent folder as well as cache', () async {
    final root = Directory('${temp.path}/win/EffectsApp')
      ..createSync(recursive: true);
    final effects = Directory('${root.path}/cache/effects/neon')
      ..createSync(recursive: true);
    File('${effects.path}/effect.html').writeAsStringSync(effectHtml('Neon'));
    File('${root.path}/cache/catalog_en.json').writeAsStringSync(
      '{"effects":[{"id":"neon","name":"Neon Cat","type":"Advanced"}]}',
    );

    final report = await importer.importWindowsCache(root.path);
    expect(report.catalogFound, isTrue);
    expect(report.imported, 1);
    expect((await library.find('neon'))!.title, 'Neon Cat');
    expect((await library.find('neon'))!.tags, ['Advanced']);
  });

  test('keeps the cache id of imported effects unchanged', () async {
    // Real catalog ids start with '-' and mix upper and lower case.
    const id = '-M0k9vv-NFE8rpM_-Br9';
    final cache = Directory('${temp.path}/win/EffectsApp/cache')
      ..createSync(recursive: true);
    Directory('${cache.path}/effects/$id').createSync(recursive: true);
    File('${cache.path}/effects/$id/effect.html')
        .writeAsStringSync(effectHtml('Fire'));
    File('${cache.path}/catalog_en.json')
        .writeAsStringSync('[{"id": "$id", "name": "Fire"}]');

    final first = await importer.importWindowsCache(cache.path);
    expect(first.imported, 1);
    expect((await library.list()).single.id, id);
    expect(Directory('${library.dir.path}/$id').existsSync(), isTrue);

    final again = await importer.importWindowsCache(cache.path);
    expect(again.imported, 0);
    expect(again.replaced, 1);
    expect(await library.list(), hasLength(1));
  });

  test('leaves paid effects out of a Windows cache import', () async {
    final cache = Directory('${temp.path}/win/EffectsApp/cache')
      ..createSync(recursive: true);
    for (final id in ['free', 'pro', 'bought']) {
      Directory('${cache.path}/effects/$id').createSync(recursive: true);
      File('${cache.path}/effects/$id/effect.html')
          .writeAsStringSync(effectHtml(id));
    }
    File('${cache.path}/catalog_en.json').writeAsStringSync('''
[
  {"id": "free", "name": "Free", "requires_pro": false, "price": 0},
  {"id": "pro", "name": "Pro", "requires_pro": true},
  {"id": "bought", "name": "Bought", "price": 2.99}
]
''');

    final report = await importer.importWindowsCache(cache.path);
    expect(report.imported, 1);
    expect(report.paidSkipped, 2);
    expect(report.issues, isEmpty);
    expect([for (final e in await library.list()) e.id], ['free']);
  });

  test('only paid effects: no "nothing found" error', () async {
    final cache = Directory('${temp.path}/win/EffectsApp/cache')
      ..createSync(recursive: true);
    Directory('${cache.path}/effects/pro').createSync(recursive: true);
    File('${cache.path}/effects/pro/effect.html')
        .writeAsStringSync(effectHtml('Pro'));
    File('${cache.path}/catalog_en.json')
        .writeAsStringSync('[{"id": "pro", "requires_pro": true}]');

    final report = await importer.importWindowsCache(cache.path);
    expect(report.paidSkipped, 1);
    expect(report.issues, isEmpty);
    expect(report.isEmpty, isFalse);
  });

  test('refuses a Windows cache without catalog_en.json', () async {
    final cache = Directory('${temp.path}/win/EffectsApp/cache')
      ..createSync(recursive: true);
    Directory('${cache.path}/effects/fire').createSync(recursive: true);
    File('${cache.path}/effects/fire/effect.html')
        .writeAsStringSync(effectHtml('Fire'));

    final report = await importer.importWindowsCache(cache.path);
    expect(report.imported, 0);
    expect(report.issues.single.kind, ImportIssueKind.catalogMissing);
    expect(await library.list(), isEmpty);
  });

  test('rejects a folder without an effects cache', () async {
    final report = await importer.importWindowsCache(temp.path);
    expect(report.imported, 0);
    expect(report.issues.single.kind, ImportIssueKind.chooseWindowsCache);
  });

  test('library writes, stores a thumbnail, and removes an effect', () async {
    final effect = await library.write(
      'Test Effect',
      effectHtml('Test Effect'),
      EffectMetadata(
        title: 'Test Effect',
        origin: EffectOrigin.zip,
        importedAt: DateTime(2026, 10, 20),
        tags: const ['Basic'],
      ),
    );
    expect(effect.id, 'test-effect');
    expect(effect.origin, EffectOrigin.zip);
    expect(effect.tags, ['Basic']);
    expect(effect.hasThumbnail, isFalse);

    await library.saveThumbnail(
      'test-effect',
      Uint8List.fromList([1, 2, 3, 4]),
    );
    expect(await library.thumbnail('test-effect'), [1, 2, 3, 4]);
    expect((await library.find('test-effect'))!.hasThumbnail, isTrue);

    await library.remove('test-effect');
    expect(await library.find('test-effect'), isNull);
    expect(await library.list(), isEmpty);
  });

  test('sanitizes ids and refuses path traversal', () async {
    expect(sanitizeEffectId('Neon Shift!'), 'neon-shift');
    expect(sanitizeEffectId('  ***  '), 'effect');
    expect(sanitizeEffectId('../../etc/passwd'), 'etc-passwd');
    expect(isSafeEffectId('ok-1.test'), isTrue);
    expect(isSafeEffectId('../x'), isFalse);
    expect(isSafeEffectId('a/b'), isFalse);
    expect(isSafeEffectId(''), isFalse);

    expect(() => library.readHtml('../fora'), throwsA(isA<FormatException>()));
    await library.remove('../fora');
    expect(await library.list(), isEmpty);
  });
}
