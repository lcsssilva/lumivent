import 'dart:convert';
import 'dart:io';

import 'bounded_file_read.dart';
import 'catalog_entry.dart';
import 'import_limits.dart';

/// Reads the `catalog_en.json` of a Windows effects cache (plan §5.3).
class WindowsEffectCatalog {
  const WindowsEffectCatalog();

  /// Catalog entries by effect id, or null when [root] has no usable catalog.
  Future<Map<String, CatalogEntry>?> read(Directory root) async {
    final name = root.uri.pathSegments.where((s) => s.isNotEmpty).last;
    final candidates = [
      if (name == 'cache') File('${root.path}/catalog_en.json'),
      File('${root.path}/catalog_en.json'),
      File('${root.path}/cache/catalog_en.json'),
    ];
    for (final f in candidates) {
      if (!await f.exists()) continue;
      try {
        final bytes = await readBounded(f, maxCatalogBytes);
        final json = jsonDecode(utf8.decode(bytes));
        final entries = parse(json);
        if (entries.isNotEmpty) return entries;
      } on Object {
        // A corrupt catalog only costs the names/tags, not the import.
      }
    }
    return null;
  }

  /// Entries of the decoded catalog [json], keyed by effect id.
  Map<String, CatalogEntry> parse(Object? json) {
    final out = <String, CatalogEntry>{};
    void add(Object? id, Object? value) {
      if (id is! String || id.isEmpty || value is! Map) return;
      final tags = <String>[];
      void addTag(Object? raw) {
        if (raw is! String) return;
        final tag = raw.trim();
        if (tag.isNotEmpty && !tags.contains(tag)) tags.add(tag);
      }

      addTag(value['type']);
      final rawTags = value['tags'];
      if (rawTags is List) rawTags.forEach(addTag);
      final price = value['price'];
      out[id] = CatalogEntry(
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
}
