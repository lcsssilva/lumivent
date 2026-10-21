// Imports HTML/Canvas effects from files, folders, ZIPs and an effects cache
// on a mounted Windows partition (plan §5.3). Only reads the paths the user
// picked; the app never mounts anything.

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';

import '../domain/effect_library.dart';
import '../domain/effect_meta.dart';
import '../domain/installed_effect.dart';
import 'effect_library.dart';

class FileEffectImporter implements EffectImporter {
  FileEffectImporter(this.library);

  final FileEffectLibrary library;

  @override
  Future<ImportReport> importPaths(List<String> paths) async {
    final report = ImportReport();
    for (final path in paths) {
      try {
        final type = FileSystemEntity.typeSync(path);
        if (type == FileSystemEntityType.directory) {
          report.add(
            await _importDirectory(Directory(path), EffectOrigin.folder),
          );
        } else if (type == FileSystemEntityType.file) {
          final lower = path.toLowerCase();
          if (lower.endsWith('.zip')) {
            report.add(await _importZip(File(path)));
          } else if (lower.endsWith('.html') || lower.endsWith('.htm')) {
            report.add(await _importFile(File(path)));
          } else {
            report.errors.add('$path: não é HTML nem ZIP');
          }
        } else {
          report.errors.add('$path: não encontrado');
        }
      } on Object catch (e) {
        report.errors.add('$path: $e');
      }
    }
    library.invalidate();
    return report;
  }

  @override
  Future<ImportReport> importWindowsCache(String folder) async {
    final report = ImportReport();
    final root = Directory(folder);
    if (!await root.exists()) {
      report.errors.add('$folder: pasta não encontrada');
      return report;
    }
    final effects = _cacheEffectsDir(root);
    if (effects == null) {
      report.errors.add('Escolha a pasta cache de efeitos do Windows.');
      return report;
    }
    final catalog = await _readCatalog(root);
    report.catalogFound = catalog != null;
    if (catalog == null) {
      // Without the catalog there is no way to tell paid effects apart.
      report.errors.add(
        'catalog_en.json não encontrado na pasta cache: sem ele não dá para '
        'saber quais efeitos são pagos.',
      );
      return report;
    }

    await for (final entry in effects.list()) {
      if (entry is! Directory) continue;
      // The folder name is the catalog id: it is kept unchanged so the
      // catalog can tell the effect is installed.
      final id = entry.uri.pathSegments.where((s) => s.isNotEmpty).last;
      final html = File('${entry.path}/effect.html');
      if (!await html.exists()) continue;
      final meta = catalog[id];
      // Paid effects are licensed to the subscriber's account in the
      // original app: they are never copied out of it.
      if (meta != null && meta.paid) {
        report.paidSkipped++;
        continue;
      }
      try {
        report.add(
          await _install(
            id: id,
            html: await html.readAsString(),
            origin: EffectOrigin.windowsCache,
            publisher: meta?.publisher,
            description: meta?.description,
            tags: meta?.tags ?? const [],
            title: meta?.title,
          ),
        );
      } on Object catch (e) {
        report.errors.add('$id: $e');
      }
    }
    if (report.total == 0 && report.paidSkipped == 0 && report.errors.isEmpty) {
      report.errors.add('Nenhum effect.html encontrado em ${effects.path}.');
    }
    library.invalidate();
    return report;
  }

  Directory? _cacheEffectsDir(Directory root) {
    final name = root.uri.pathSegments.where((s) => s.isNotEmpty).last;
    final candidates = [
      if (name == 'effects') root,
      Directory('${root.path}/effects'),
      Directory('${root.path}/cache/effects'),
    ];
    for (final d in candidates) {
      if (d.existsSync() && d.listSync().any((e) => e is Directory)) return d;
    }
    return null;
  }

  Future<Map<String, _CatalogEntry>?> _readCatalog(Directory root) async {
    final name = root.uri.pathSegments.where((s) => s.isNotEmpty).last;
    final candidates = [
      if (name == 'cache') File('${root.path}/catalog_en.json'),
      File('${root.path}/catalog_en.json'),
      File('${root.path}/cache/catalog_en.json'),
    ];
    for (final f in candidates) {
      if (!await f.exists()) continue;
      try {
        final json = jsonDecode(await f.readAsString());
        final entries = _catalogEntries(json);
        if (entries.isNotEmpty) return entries;
      } on Object {
        // A corrupt catalog only costs the names/tags, not the import.
      }
    }
    return null;
  }

  Map<String, _CatalogEntry> _catalogEntries(Object? json) {
    final out = <String, _CatalogEntry>{};
    void add(Object? id, Object? value) {
      if (id is! String || id.isEmpty || value is! Map) return;
      final tags = <String>[];
      final type = value['type'];
      if (type is String && type.isNotEmpty) tags.add(type);
      final rawTags = value['tags'];
      if (rawTags is List) {
        tags.addAll([
          for (final t in rawTags)
            if (t is String && t.isNotEmpty && !tags.contains(t)) t,
        ]);
      }
      final price = value['price'];
      out[id] = _CatalogEntry(
        paid: value['requires_pro'] == true || (price is num && price > 0),
        title: value['name'] is String ? value['name'] as String : null,
        publisher: value['publisher'] is String
            ? value['publisher'] as String
            : null,
        description: value['description'] is String
            ? value['description'] as String
            : null,
        tags: tags,
      );
    }

    if (json is List) {
      for (final e in json) {
        if (e is Map) add(e['id'] ?? e['name'], e);
      }
    } else if (json is Map) {
      for (final e in json.entries) {
        if (e.value is List) {
          for (final item in e.value as List) {
            if (item is Map) add(item['id'] ?? item['name'], item);
          }
        } else {
          add(e.key, e.value);
        }
      }
    }
    return out;
  }

  Future<ImportReport> _importFile(File file) async {
    final html = await file.readAsString();
    final base = file.uri.pathSegments.where((s) => s.isNotEmpty).last;
    final title = parseEffect(html).title;
    final id = _idFor(
      title,
      base.replaceAll(RegExp(r'\.html?$', caseSensitive: false), ''),
    );
    return _install(id: id, html: html, origin: EffectOrigin.file);
  }

  Future<ImportReport> _importDirectory(
    Directory dir,
    EffectOrigin origin,
  ) async {
    final report = ImportReport();
    final direct = File('${dir.path}/effect.html');
    if (await direct.exists()) {
      final base = dir.uri.pathSegments.where((s) => s.isNotEmpty).last;
      final html = await direct.readAsString();
      return _install(
        id: _idFor(parseEffect(html).title, base),
        html: html,
        origin: origin,
      );
    }

    final htmlFiles = <File>[];
    await for (final e in dir.list()) {
      if (e is Directory) {
        final f = File('${e.path}/effect.html');
        if (await f.exists()) htmlFiles.add(f);
      } else if (e is File &&
          (e.path.toLowerCase().endsWith('.html') ||
              e.path.toLowerCase().endsWith('.htm'))) {
        htmlFiles.add(e);
      }
    }
    if (htmlFiles.isEmpty) {
      report.errors.add('${dir.path}: nenhum effect.html encontrado');
      return report;
    }
    for (final f in htmlFiles) {
      try {
        final parent = f.parent.uri.pathSegments
            .where((s) => s.isNotEmpty)
            .last;
        final isDirect = f.parent.path == dir.path;
        final base = isDirect
            ? f.uri.pathSegments
                  .where((s) => s.isNotEmpty)
                  .last
                  .replaceAll(RegExp(r'\.html?$', caseSensitive: false), '')
            : parent;
        final html = await f.readAsString();
        report.add(
          await _install(
            id: _idFor(parseEffect(html).title, base),
            html: html,
            origin: origin,
          ),
        );
      } on Object catch (e) {
        report.errors.add('${f.path}: $e');
      }
    }
    return report;
  }

  Future<ImportReport> _importZip(File file) async {
    final report = ImportReport();
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(await file.readAsBytes());
    } on Object catch (e) {
      report.errors.add('${file.path}: ZIP inválido ($e)');
      return report;
    }
    final zipBase = file.uri.pathSegments
        .where((s) => s.isNotEmpty)
        .last
        .replaceAll(RegExp(r'\.zip$', caseSensitive: false), '');
    var found = 0;
    for (final entry in archive) {
      if (!entry.isFile) continue;
      final name = entry.name.replaceAll('\\', '/');
      if (name.startsWith('/') || name.split('/').contains('..')) continue;
      final lower = name.toLowerCase();
      if (!lower.endsWith('.html') && !lower.endsWith('.htm')) continue;
      found++;
      try {
        final parts = name.split('/').where((s) => s.isNotEmpty).toList();
        final fileBase = parts.last.replaceAll(
          RegExp(r'\.html?$', caseSensitive: false),
          '',
        );
        final base = parts.length > 1 ? parts[parts.length - 2] : zipBase;
        // `effect.html` is the standard name: the folder names the effect.
        final isEffect = parts.last.toLowerCase() == 'effect.html';
        final html = utf8.decode(entry.content, allowMalformed: true);
        report.add(
          await _install(
            id: _idFor(parseEffect(html).title, isEffect ? base : fileBase),
            html: html,
            origin: EffectOrigin.zip,
          ),
        );
      } on Object catch (e) {
        report.errors.add('$name: $e');
      }
    }
    if (found == 0) report.errors.add('O ZIP não tem arquivos HTML.');
    return report;
  }

  Future<ImportReport> _install({
    required String id,
    required String html,
    required EffectOrigin origin,
    String? title,
    String? publisher,
    String? description,
    List<String> tags = const [],
  }) async {
    final source = parseEffect(html);
    final metadata = EffectMetadata(
      title: (title ?? source.title).trim().isEmpty
          ? id
          : (title ?? source.title).trim(),
      origin: origin,
      importedAt: DateTime.now(),
      publisher: publisher ?? source.publisher,
      description: description ?? source.description,
      tags: tags,
    );
    final safe = FileEffectLibrary.storageId(id);
    final existed = await library.exists(safe);
    await library.write(safe, html, metadata);
    return ImportReport(imported: existed ? 0 : 1, replaced: existed ? 1 : 0);
  }

  /// Avoids an empty or overlong id, keeping cache ids intact.
  String _idFor(String title, String fallback) {
    final raw = fallback.trim().isNotEmpty ? fallback : title;
    return sanitizeEffectId(raw.length > 80 ? raw.substring(0, 80) : raw);
  }
}

class _CatalogEntry {
  const _CatalogEntry({
    this.title,
    this.publisher,
    this.description,
    this.tags = const [],
    this.paid = false,
  });
  final String? title, publisher, description;
  final List<String> tags;

  /// Requires a subscription or a purchase in the original app.
  final bool paid;
}
