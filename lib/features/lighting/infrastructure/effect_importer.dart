// Imports HTML/Canvas effects from files, folders, ZIPs and an effects cache
// on a mounted Windows partition (plan §5.3). Only reads the paths the user
// picked; the app never mounts anything.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../domain/effect_library.dart';
import '../domain/effect_meta.dart';
import '../domain/installed_effect.dart';
import 'effect_library.dart';

const _maxHtmlBytes = 4 * 1024 * 1024;
const _maxZipBytes = 64 * 1024 * 1024;
const _maxZipHtmlBytes = 32 * 1024 * 1024;
const _maxCatalogBytes = 8 * 1024 * 1024;

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
            report.issues.add(
              ImportIssue(ImportIssueKind.notHtmlOrZip, path: path),
            );
          }
        } else {
          report.issues.add(ImportIssue(ImportIssueKind.notFound, path: path));
        }
      } on Object catch (e) {
        report.issues.add(
          ImportIssue(ImportIssueKind.unknown, path: path, detail: '$e'),
        );
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
      report.issues.add(
        ImportIssue(ImportIssueKind.folderNotFound, path: folder),
      );
      return report;
    }
    final effects = _cacheEffectsDir(root);
    if (effects == null) {
      report.issues.add(const ImportIssue(ImportIssueKind.chooseWindowsCache));
      return report;
    }
    final catalog = await _readCatalog(root);
    report.catalogFound = catalog != null;
    if (catalog == null) {
      // Without the catalog there is no way to tell paid effects apart.
      report.issues.add(const ImportIssue(ImportIssueKind.catalogMissing));
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
            html: await _readHtml(html),
            origin: EffectOrigin.windowsCache,
            publisher: meta?.publisher,
            description: meta?.description,
            tags: meta?.tags ?? const [],
            title: meta?.title,
          ),
        );
      } on Object catch (e) {
        report.issues.add(
          ImportIssue(ImportIssueKind.unknown, path: id, detail: '$e'),
        );
      }
    }
    if (report.total == 0 && report.paidSkipped == 0 && report.issues.isEmpty) {
      report.issues.add(
        ImportIssue(ImportIssueKind.noEffectHtml, path: effects.path),
      );
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
        final bytes = await _readBounded(f, _maxCatalogBytes);
        final json = jsonDecode(utf8.decode(bytes));
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
    final html = await _readHtml(file);
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
      final html = await _readHtml(direct);
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
      report.issues.add(
        ImportIssue(ImportIssueKind.noEffectHtml, path: dir.path),
      );
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
        final html = await _readHtml(f);
        report.add(
          await _install(
            id: _idFor(parseEffect(html).title, base),
            html: html,
            origin: origin,
          ),
        );
      } on Object catch (e) {
        report.issues.add(
          ImportIssue(ImportIssueKind.unknown, path: f.path, detail: '$e'),
        );
      }
    }
    return report;
  }

  /// Unix file types that name regular files: no type bits, or S_IFREG.
  static const Set<int> _regularEntryTypes = {0x0000, 0x8000};
  static const int _unixDirectoryType = 0x4000;

  Future<ImportReport> _importZip(File file) async {
    final report = ImportReport();
    final Uint8List bytes;
    try {
      bytes = await _readBounded(file, _maxZipBytes);
    } on Object catch (e) {
      report.issues.add(
        ImportIssue(ImportIssueKind.invalidZip, path: file.path, detail: '$e'),
      );
      return report;
    }
    // Only the central directory is read here. Archiver versions that decode
    // entries eagerly would decompress symlink targets and other payload
    // while building the archive object, before the limits below apply.
    final ZipDirectory directory;
    try {
      directory = ZipDirectory()..read(InputMemoryStream(bytes));
    } on Object catch (e) {
      report.issues.add(
        ImportIssue(ImportIssueKind.invalidZip, path: file.path, detail: '$e'),
      );
      return report;
    }
    final zipBase = file.uri.pathSegments
        .where((s) => s.isNotEmpty)
        .last
        .replaceAll(RegExp(r'\.zip$', caseSensitive: false), '');
    var found = 0;
    var totalHtmlBytes = 0;
    for (final header in directory.fileHeaders) {
      final zipFile = header.file;
      if (zipFile == null) continue;
      final name = header.filename.replaceAll('\\', '/');
      if (name.startsWith('/') || name.split('/').contains('..')) continue;
      final lower = name.toLowerCase();
      if (!lower.endsWith('.html') && !lower.endsWith('.htm')) continue;
      // Symlinks, devices and other non-regular entries are never HTML:
      // they are rejected before their payload is read or decompressed.
      final entryType = (header.externalFileAttributes >> 16) & 0xf000;
      if (entryType == _unixDirectoryType) continue;
      if (!_regularEntryTypes.contains(entryType)) {
        report.issues.add(
          ImportIssue(
            ImportIssueKind.unknown,
            path: name,
            detail:
                'Zip entry type is not supported (reported as a symlink '
                'or non-regular file)',
          ),
        );
        continue;
      }
      found++;
      try {
        final size = header.uncompressedSize;
        if (size < 0 ||
            size > _maxHtmlBytes ||
            totalHtmlBytes + size > _maxZipHtmlBytes) {
          report.issues.add(
            ImportIssue(
              ImportIssueKind.unknown,
              path: name,
              detail: 'HTML entry exceeds the import size limit',
            ),
          );
          continue;
        }
        totalHtmlBytes += size;
        final parts = name.split('/').where((s) => s.isNotEmpty).toList();
        final fileBase = parts.last.replaceAll(
          RegExp(r'\.html?$', caseSensitive: false),
          '',
        );
        final base = parts.length > 1 ? parts[parts.length - 2] : zipBase;
        // `effect.html` is the standard name: the folder names the effect.
        final isEffect = parts.last.toLowerCase() == 'effect.html';
        // Decompression also stops at the declared size inside the archive
        // library; the declared size is bounded by the check above.
        final content = zipFile.readBytes();
        if (content.length > _maxHtmlBytes) {
          report.issues.add(
            ImportIssue(
              ImportIssueKind.unknown,
              path: name,
              detail: 'HTML entry exceeds the import size limit',
            ),
          );
          continue;
        }
        final html = utf8.decode(content, allowMalformed: true);
        report.add(
          await _install(
            id: _idFor(parseEffect(html).title, isEffect ? base : fileBase),
            html: html,
            origin: EffectOrigin.zip,
          ),
        );
      } on Object catch (e) {
        report.issues.add(
          ImportIssue(ImportIssueKind.unknown, path: name, detail: '$e'),
        );
      }
    }
    if (found == 0) {
      report.issues.add(const ImportIssue(ImportIssueKind.noHtmlInZip));
    }
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

  Future<String> _readHtml(File file) async => utf8.decode(
    await _readBounded(file, _maxHtmlBytes),
    allowMalformed: true,
  );

  Future<Uint8List> _readBounded(File file, int limit) async {
    final bytes = BytesBuilder(copy: false);
    var length = 0;
    await for (final chunk in file.openRead()) {
      length += chunk.length;
      if (length > limit) {
        throw FormatException('File exceeds the $limit-byte import limit');
      }
      bytes.add(chunk);
    }
    return bytes.takeBytes();
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
