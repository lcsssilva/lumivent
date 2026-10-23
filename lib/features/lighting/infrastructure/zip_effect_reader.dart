import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../domain/import_issue.dart';
import '../domain/effect_library.dart';
import '../domain/import_report.dart';
import 'bounded_file_read.dart';
import 'import_issue_for.dart';
import 'import_limits.dart';
import 'import_too_large.dart';
import 'zip_html_entry.dart';

/// Extracts HTML effects from a ZIP, enforcing the archive limits: path
/// traversal, entry types, per-file and total HTML size.
class ZipEffectReader {
  const ZipEffectReader();

  /// Unix file types that name regular files: no type bits, or S_IFREG.
  static const Set<int> _regularEntryTypes = {0x0000, 0x8000};
  static const int _unixDirectoryType = 0x4000;

  /// Opens [file] and returns its HTML entries lazily, so that each entry is
  /// decompressed only when the caller asks for it. Problems are added to
  /// [report]; returns null when the archive cannot be read.
  Future<Iterable<ZipHtmlEntry>?> open(File file, ImportReport report) async {
    final Uint8List bytes;
    try {
      bytes = await readBounded(file, maxZipBytes);
    } on Object catch (e) {
      report.issues.add(
        e is ImportTooLarge
            ? ImportIssue(ImportIssueKind.tooLarge, path: file.path)
            : ImportIssue(
                ImportIssueKind.invalidZip,
                path: file.path,
                detail: '$e',
              ),
      );
      return null;
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
      return null;
    }
    final zipBase = file.uri.pathSegments
        .where((s) => s.isNotEmpty)
        .last
        .replaceAll(RegExp(r'\.zip$', caseSensitive: false), '');
    return _entries(directory, zipBase, report);
  }

  Iterable<ZipHtmlEntry> _entries(
    ZipDirectory directory,
    String zipBase,
    ImportReport report,
  ) sync* {
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
          ImportIssue(ImportIssueKind.unsupportedZipEntry, path: name),
        );
        continue;
      }
      found++;
      ZipHtmlEntry entry;
      try {
        final size = header.uncompressedSize;
        if (size < 0 ||
            size > maxHtmlBytes ||
            totalHtmlBytes + size > maxZipHtmlBytes) {
          report.issues.add(ImportIssue(ImportIssueKind.tooLarge, path: name));
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
        if (content.length > maxHtmlBytes) {
          report.issues.add(ImportIssue(ImportIssueKind.tooLarge, path: name));
          continue;
        }
        entry = ZipHtmlEntry(
          name: name,
          html: utf8.decode(content, allowMalformed: true),
          fallbackName: isEffect ? base : fileBase,
        );
      } on Object catch (e) {
        report.issues.add(importIssueFor(name, e));
        continue;
      }
      yield entry;
    }
    if (found == 0) {
      report.issues.add(const ImportIssue(ImportIssueKind.noHtmlInZip));
    }
  }
}
