// Explore module application (pure Dart): searching and filtering the installed
// effects. Uses the lighting public API for the effect model.

import '../../lighting/lighting.dart';

/// Effects with a given compatibility badge, plus "all".
enum SupportFilter { all, compatible, partial, unsupported }

class EffectFilter {
  const EffectFilter({
    this.query = '',
    this.support = SupportFilter.all,
    this.tag,
    this.publisher,
  });

  final String query;
  final SupportFilter support;

  /// Catalog tag (`Basic`, `Advanced`, `Audio`, `Pro`…), `null` for any.
  final String? tag;

  /// Publisher name, `null` for any.
  final String? publisher;

  bool get isActive =>
      query.trim().isNotEmpty ||
      support != SupportFilter.all ||
      tag != null ||
      publisher != null;

  bool matches(InstalledEffect effect) {
    if (!_matchesSupport(effect.compatibility.support)) return false;
    final wantedTag = tag;
    if (wantedTag != null && !_hasTag(effect, wantedTag)) return false;
    if (publisher != null && effect.publisher != publisher) return false;
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return effect.title.toLowerCase().contains(q) ||
        (effect.publisher?.toLowerCase().contains(q) ?? false) ||
        (effect.description?.toLowerCase().contains(q) ?? false) ||
        effect.tags.any((t) => t.toLowerCase().contains(q));
  }

  /// Tags are compared trimmed, the same way [availableTags] offers them.
  static bool _hasTag(InstalledEffect effect, String wantedTag) {
    final wanted = wantedTag.trim();
    return effect.tags.any((t) => t.trim() == wanted);
  }

  bool _matchesSupport(EffectSupport s) => switch (support) {
    SupportFilter.all => true,
    SupportFilter.compatible => s == EffectSupport.compatible,
    SupportFilter.partial => s == EffectSupport.partial,
    SupportFilter.unsupported => s == EffectSupport.unsupported,
  };
}

List<InstalledEffect> filterEffects(
  Iterable<InstalledEffect> effects,
  EffectFilter filter,
) => [
  for (final e in effects)
    if (filter.matches(e)) e,
];

/// Sorted catalog tags present in [effects] (Basic, Advanced, Audio, Pro…).
List<String> availableTags(Iterable<InstalledEffect> effects) {
  final tags = {
    for (final e in effects)
      for (final t in e.tags)
        if (t.trim().isNotEmpty) t.trim(),
  }.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return tags;
}

/// Sorted publishers present in [effects].
List<String> availablePublishers(Iterable<InstalledEffect> effects) {
  final names = {
    for (final e in effects)
      if (e.publisher != null && e.publisher!.trim().isNotEmpty)
        e.publisher!.trim(),
  }.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return names;
}
