import 'installed_effect.dart';

/// Metadata written next to `effect.html` (no script, no derived fields).
class EffectMetadata {
  const EffectMetadata({
    required this.title,
    required this.origin,
    required this.importedAt,
    this.publisher,
    this.description,
    this.tags = const [],
  });

  final String title;
  final EffectOrigin origin;
  final DateTime importedAt;
  final String? publisher, description;
  final List<String> tags;

  Map<String, Object?> toJson() => {
    'title': title,
    'origin': origin.name,
    'importedAt': importedAt.toIso8601String(),
    if (publisher != null) 'publisher': publisher,
    if (description != null) 'description': description,
    if (tags.isNotEmpty) 'tags': tags,
  };

  factory EffectMetadata.fromJson(
    Map<String, Object?> json,
    String fallbackTitle,
  ) {
    final origin = EffectOrigin.values
        .where((o) => o.name == json['origin'])
        .firstOrNull;
    final at = json['importedAt'];
    final rawTags = json['tags'];
    return EffectMetadata(
      title: json['title'] is String && (json['title'] as String).isNotEmpty
          ? json['title'] as String
          : fallbackTitle,
      origin: origin ?? EffectOrigin.file,
      importedAt: at is String
          ? (DateTime.tryParse(at) ?? DateTime.now())
          : DateTime.now(),
      publisher: json['publisher'] is String
          ? json['publisher'] as String
          : null,
      description: json['description'] is String
          ? json['description'] as String
          : null,
      tags: rawTags is List
          ? [
              for (final t in rawTags)
                if (t is String && t.trim().isNotEmpty) t.trim(),
            ]
          : const [],
    );
  }
}
