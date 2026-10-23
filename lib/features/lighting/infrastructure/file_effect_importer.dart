// Imports HTML/Canvas effects from files, folders, ZIPs and an effects cache
// on a mounted Windows partition (plan §5.3). Only reads the paths the user
// picked; the app never mounts anything.

import 'dart:convert';
import 'dart:io';

import '../domain/effect_library.dart';
import '../domain/import_issue.dart';
import '../domain/import_report.dart';
import '../domain/effect_importer.dart';
import '../domain/effect_meta.dart';
import '../domain/installed_effect.dart';
import '../domain/effect_metadata.dart';
import 'bounded_file_read.dart';
import 'file_effect_library.dart';
import 'import_issue_for.dart';
import 'import_limits.dart';
import 'windows_effect_catalog.dart';
import 'zip_effect_reader.dart';

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
        report.issues.add(importIssueFor(path, e));
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
    final catalog = await const WindowsEffectCatalog().read(root);
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
        report.issues.add(importIssueFor(id, e));
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
        report.issues.add(importIssueFor(f.path, e));
      }
    }
    return report;
  }

  Future<ImportReport> _importZip(File file) async {
    final report = ImportReport();
    final entries = await const ZipEffectReader().open(file, report);
    if (entries == null) return report;
    for (final entry in entries) {
      try {
        report.add(
          await _install(
            id: _idFor(parseEffect(entry.html).title, entry.fallbackName),
            html: entry.html,
            origin: EffectOrigin.zip,
          ),
        );
      } on Object catch (e) {
        report.issues.add(importIssueFor(entry.name, e));
      }
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

  Future<String> _readHtml(File file) async =>
      utf8.decode(await readBounded(file, maxHtmlBytes), allowMalformed: true);
}
