// Static compatibility check of an HTML/Canvas effect (plan §5.4): what the
// effect script asks from the host that this app does not provide.

import 'package:freezed_annotation/freezed_annotation.dart';

import 'effect_meta.dart';

part 'effect_compat.freezed.dart';

enum EffectSupport {
  /// Everything the script uses is available (or safely stubbed).
  compatible,

  /// Runs, but some input is missing (audio is silence, images are blank).
  partial,

  /// Needs screen capture, pixel reads, or another absent API.
  unsupported,
}

/// Feature an effect needs from the host. The presentation maps the index to
/// the catalog (`LightingStrings.compatibilityIssue`).
enum EffectIssue { capture, pixels, audio, images, api }

@freezed
abstract class EffectCompatibility with _$EffectCompatibility {
  const factory EffectCompatibility(
    EffectSupport support,

    /// Missing features, without user-facing text.
    List<EffectIssue> issues,
  ) = _EffectCompatibility;
}

extension EffectCompatibilityX on EffectCompatibility {
  bool get canRun => support != EffectSupport.unsupported;
}

/// APIs that make an effect unusable with this runtime.
const _unsupported = <(String, EffectIssue)>[
  ('engine.zone', EffectIssue.capture),
  ('screenCapture', EffectIssue.capture),
  ('desktopCapturer', EffectIssue.capture),
  ('getImageData', EffectIssue.pixels),
];

/// APIs that work with a stub, degrading the effect.
const _partial = <(String, EffectIssue)>[
  ('engine.audio', EffectIssue.audio),
  ('drawImage', EffectIssue.images),
];

/// Analyzes the effect script (and its property types).
EffectCompatibility analyzeEffect(EffectSource effect) {
  final script = effect.script;
  final issues = <EffectIssue>[];

  for (final (api, issue) in _unsupported) {
    if (script.contains(api)) _append(issues, issue);
  }
  for (final (api, issue) in _partial) {
    if (script.contains(api)) _append(issues, issue);
  }
  if (effect.properties.any((p) => p.type.toLowerCase() == 'audio')) {
    _append(issues, EffectIssue.audio);
  }

  const blocking = {EffectIssue.capture, EffectIssue.pixels};
  if (issues.any(blocking.contains)) {
    return EffectCompatibility(EffectSupport.unsupported, issues);
  }
  return EffectCompatibility(
    issues.isEmpty ? EffectSupport.compatible : EffectSupport.partial,
    issues,
  );
}

void _append(List<EffectIssue> list, EffectIssue value) {
  if (!list.contains(value)) list.add(value);
}
