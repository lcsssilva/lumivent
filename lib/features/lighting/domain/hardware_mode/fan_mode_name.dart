import '../config/lighting_config.dart';

/// Grammar of the AL V2 firmware mode names: `<Base>` for the whole fan and
/// `<Base>_Inner`, `<Base>_Outer` or `<Base>_Merge` for a scope variant. The
/// byte tables belong to devices; the config and the UI only handle names.
enum FanModeSuffix {
  inner('_Inner'),
  outer('_Outer'),
  merge('_Merge');

  const FanModeSuffix(this.text);
  final String text;
}

final _scopeSuffix = RegExp(r'_(Inner|Outer|Merge)$');
final _mergeSuffix = RegExp(r'_Merge$');

/// The base name of [name] without its scope suffix: `Wave_Inner` -> `Wave`.
String fanModeBase(String name) => name.replaceFirst(_scopeSuffix, '');

/// The mode name of [base] in the scope variant [suffix]; the whole-fan name
/// when [suffix] is null.
String fanModeName(String base, [FanModeSuffix? suffix]) =>
    '$base${suffix?.text ?? ''}';

/// Base name of a merge mode: `Runway_Merge` -> `Runway`. Names without the
/// merge suffix are returned unchanged.
String mergeModeBase(String name) => name.replaceFirst(_mergeSuffix, '');

/// Fallback merge base when the stored one is not a known merge mode.
const defaultMergeBase = 'Runway';

/// Accepts `Runway` and `Runway_Merge`; returns a base name that is in
/// [mergeBases] (falls back to [defaultMergeBase]).
String normalizeMergeBase(String name, Iterable<String> mergeBases) {
  final base = mergeModeBase(name);
  return mergeBases.contains(base) ? base : defaultMergeBase;
}

/// Keeps the same effect when the scope changes (`Wave` <-> `Wave_Inner`).
/// [isKnown] tells whether a mode name exists in the firmware table; without
/// the converted name the mode falls back to `StaticColor` of the scope.
String convertFanModeScope(
  String name,
  Alv2Scope to, {
  required bool Function(String name) isKnown,
}) {
  final suffix = to == Alv2Scope.whole ? null : FanModeSuffix.inner;
  final candidate = fanModeName(fanModeBase(name), suffix);
  return isKnown(candidate) ? candidate : fanModeName('StaticColor', suffix);
}
