// File-backed installed-effect library: `~/.local/share/lumivent/effects/`
// with one folder per effect (`effect.html`, `effect.json`, `thumbnail.png`).
//
// (plan §5.2)

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../domain/effect_compat.dart';
import '../domain/effect_library.dart';
import '../domain/effect_meta.dart';
import '../domain/installed_effect.dart';

/// `$XDG_DATA_HOME/lumivent/effects`, or `~/.local/share/lumivent/effects`.
Directory defaultEffectsDir([Map<String, String>? env]) {
  env ??= Platform.environment;
  final xdg = env['XDG_DATA_HOME'];
  final base = (xdg != null && xdg.isNotEmpty)
      ? xdg
      : '${env['HOME']}/.local/share';
  return Directory('$base/lumivent/effects');
}

/// Effects ids are folder names: keep them filesystem- and URL-safe.
String sanitizeEffectId(String raw) {
  final slug = raw
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9._-]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^[.-]+|[.-]+$'), '');
  return slug.isEmpty ? 'efeito' : slug;
}

/// `true` when [id] is a single, safe path segment.
bool isSafeEffectId(String id) =>
    id.isNotEmpty &&
    id != '.' &&
    id != '..' &&
    !id.contains('/') &&
    !id.contains('\\') &&
    RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(id);

class FileEffectLibrary implements EffectLibrary {
  FileEffectLibrary(this.dir);

  final Directory dir;

  Map<String, InstalledEffect>? _cache;

  File _html(String id) => File('${dir.path}/$id/effect.html');
  File _metadata(String id) => File('${dir.path}/$id/effect.json');
  File _thumbnail(String id) => File('${dir.path}/$id/thumbnail.png');

  /// Drops the in-memory list (after an import or removal).
  void invalidate() => _cache = null;

  @override
  Future<List<InstalledEffect>> list() async {
    final cached = _cache;
    if (cached != null) return cached.values.toList();
    final out = <String, InstalledEffect>{};
    // Synchronous IO: the folder is small, and the async version could leave
    // the Explore page loading forever in widget tests (fake async).
    if (!dir.existsSync()) return const [];
    for (final entry in dir.listSync()) {
      if (entry is! Directory) continue;
      final id = entry.uri.pathSegments.where((s) => s.isNotEmpty).last;
      if (!isSafeEffectId(id)) continue;
      try {
        final effect = _load(id);
        if (effect != null) out[id] = effect;
      } on Object {
        // An unreadable folder must not hide the rest of the library.
      }
    }
    final sorted = out.values.toList()
      ..sort((a, b) {
        final at = a.importedAt, bt = b.importedAt;
        if (at != null && bt != null && at != bt) return bt.compareTo(at);
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
    _cache = {for (final e in sorted) e.id: e};
    return sorted;
  }

  @override
  Future<InstalledEffect?> find(String id) async {
    if (!isSafeEffectId(id)) return null;
    final cached = _cache?[id];
    if (cached != null) return cached;
    return _load(id);
  }

  @override
  Future<String> readHtml(String id) async {
    if (!isSafeEffectId(id)) {
      throw const FormatException('Invalid effect.');
    }
    final f = _html(id);
    if (!f.existsSync()) {
      throw FormatException('Effect $id is not installed.');
    }
    return f.readAsString();
  }

  @override
  Future<void> remove(String id) async {
    if (!isSafeEffectId(id)) return;
    final folder = Directory('${dir.path}/$id');
    if (folder.existsSync()) folder.deleteSync(recursive: true);
    _cache?.remove(id);
  }

  @override
  Future<void> saveThumbnail(String id, Uint8List png) async {
    if (!isSafeEffectId(id)) return;
    final folder = Directory('${dir.path}/$id');
    if (!folder.existsSync()) return;
    _thumbnail(id).writeAsBytesSync(png, flush: true);
  }

  @override
  Future<Uint8List?> thumbnail(String id) async {
    if (!isSafeEffectId(id)) return null;
    final f = _thumbnail(id);
    return f.existsSync() ? f.readAsBytesSync() : null;
  }

  /// Folder name used for [id]: kept as is when it is already a safe segment
  /// (cache ids, e.g. `-M03jnAFdruOhhWbn3Ge`, must match the
  /// catalog exactly), sanitized otherwise.
  static String storageId(String id) =>
      isSafeEffectId(id) ? id : sanitizeEffectId(id);

  /// Writes (or replaces) effect [id]. Used by the importer.
  Future<InstalledEffect> write(
    String id,
    String html,
    EffectMetadata metadata,
  ) async {
    final safe = storageId(id);
    final folder = Directory('${dir.path}/$safe');
    folder.createSync(recursive: true);
    _html(safe).writeAsStringSync(html, flush: true);
    _metadata(safe).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(metadata.toJson()),
      flush: true,
    );
    _cache = null;
    final effect = _load(safe);
    if (effect == null) {
      throw FormatException('$safe is not a valid effect file.');
    }
    return effect;
  }

  /// Whether [id] is already installed.
  Future<bool> exists(String id) async =>
      isSafeEffectId(id) && _html(id).existsSync();

  InstalledEffect? _load(String id) {
    if (!isSafeEffectId(id)) return null;
    final file = _html(id);
    if (!file.existsSync()) return null;
    final html = file.readAsStringSync();
    final source = parseEffect(html);
    EffectMetadata? meta;
    try {
      final raw = _metadata(id).readAsStringSync();
      final json = jsonDecode(raw);
      if (json is Map) {
        meta = EffectMetadata.fromJson({
          for (final e in json.entries)
            if (e.key is String) e.key as String: e.value,
        }, source.title);
      }
    } on Object {
      meta = null;
    }
    final compatibility = analyzeEffect(source);
    return InstalledEffect(
      id: id,
      title: (meta?.title ?? source.title).trim().isEmpty
          ? id
          : (meta?.title ?? source.title).trim(),
      source: source,
      compatibility: compatibility,
      publisher: _nonEmpty(meta?.publisher) ?? _nonEmpty(source.publisher),
      description:
          _nonEmpty(meta?.description) ?? _nonEmpty(source.description),
      origin: meta?.origin ?? EffectOrigin.file,
      importedAt: meta?.importedAt,
      tags: meta?.tags ?? const [],
      hasThumbnail: _thumbnail(id).existsSync(),
    );
  }

  static String? _nonEmpty(String? s) =>
      s == null || s.trim().isEmpty ? null : s.trim();
}
