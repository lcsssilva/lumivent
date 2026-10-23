// Lighting module domain (pure Dart): installed HTML/Canvas effects
// files (plan §5.2). The library stores `effect.html` plus this metadata.

import 'package:freezed_annotation/freezed_annotation.dart';

import 'effect_compat.dart';
import 'effect_meta.dart';

part 'installed_effect.freezed.dart';

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

@freezed
abstract class InstalledEffect with _$InstalledEffect {
  const factory InstalledEffect({
    /// Folder name inside the effects directory.
    required String id,
    required String title,
    required EffectSource source,
    required EffectCompatibility compatibility,
    String? publisher,
    String? description,
    @Default(EffectOrigin.file) EffectOrigin origin,
    DateTime? importedAt,

    /// Extra catalog metadata (type, tags) when imported from a Windows cache.
    @Default(<String>[]) List<String> tags,
    @Default(false) bool hasThumbnail,
  }) = _InstalledEffect;
}

extension InstalledEffectX on InstalledEffect {
  /// `LightingConfig.effectId` of this effect.
  String get effectId => htmlEffectId(id);

  bool get canRun => compatibility.canRun;
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
                if (t is String && t.trim().isNotEmpty) t.trim(),
            ]
          : const [],
    );
  }
}
