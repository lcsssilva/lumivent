// Lighting module domain (pure Dart): installed HTML/Canvas effects
// files (plan §5.2). The library stores `effect.html` plus this metadata.

import 'effect_compat.dart';
import 'effect_meta.dart';

/// Prefix of an installed effect inside `LightingConfig.effectId`.
const htmlEffectPrefix = 'html:';

/// `LightingConfig.effectId` of installed effect [id].
String htmlEffectId(String id) => '$htmlEffectPrefix$id';

/// Installed effect id inside [effectId], or `null` for a native effect.
String? htmlEffectSlugOf(String effectId) =>
    effectId.startsWith(htmlEffectPrefix)
    ? effectId.substring(htmlEffectPrefix.length)
    : null;

/// Where an installed effect came from (shown in the Explore page).
enum EffectOrigin { file, folder, zip, windowsCache }

String effectOriginLabel(EffectOrigin origin) => switch (origin) {
  EffectOrigin.file => 'Arquivo HTML',
  EffectOrigin.folder => 'Pasta',
  EffectOrigin.zip => 'ZIP',
  EffectOrigin.windowsCache => 'Windows',
};

class InstalledEffect {
  const InstalledEffect({
    required this.id,
    required this.title,
    required this.source,
    required this.compatibility,
    this.publisher,
    this.description,
    this.origin = EffectOrigin.file,
    this.importedAt,
    this.tags = const [],
    this.hasThumbnail = false,
  });

  /// Folder name inside the effects directory.
  final String id;
  final String title;
  final EffectSource source;
  final EffectCompatibility compatibility;
  final String? publisher, description;
  final EffectOrigin origin;
  final DateTime? importedAt;

  /// Extra catalog metadata (type, tags) when imported from a Windows cache.
  final List<String> tags;
  final bool hasThumbnail;

  /// `LightingConfig.effectId` of this effect.
  String get effectId => htmlEffectId(id);

  bool get canRun => compatibility.canRun;

  InstalledEffect copyWith({bool? hasThumbnail}) => InstalledEffect(
    id: id,
    title: title,
    source: source,
    compatibility: compatibility,
    publisher: publisher,
    description: description,
    origin: origin,
    importedAt: importedAt,
    tags: tags,
    hasThumbnail: hasThumbnail ?? this.hasThumbnail,
  );
}

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
                if (t is String && t.isNotEmpty) t,
            ]
          : const [],
    );
  }
}
