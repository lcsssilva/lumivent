// Lighting module domain (pure Dart): installed HTML/Canvas effects
// files (plan §5.2). The library stores `effect.html` plus this metadata.

import 'package:freezed_annotation/freezed_annotation.dart';

import 'effect_compatibility.dart';
import 'effect_source.dart';

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
