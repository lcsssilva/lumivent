// Static compatibility check of an HTML/Canvas effect (plan §5.4): what the
// effect script asks from the host that this app does not provide.

import 'effect_meta.dart';

enum EffectSupport {
  /// Everything the script uses is available (or safely stubbed).
  compatible,

  /// Runs, but some input is missing (audio is silence, images are blank).
  partial,

  /// Needs screen capture, pixel reads, or another absent API.
  unsupported,
}

class EffectCompatibility {
  const EffectCompatibility(this.support, this.issues);

  final EffectSupport support;

  /// Short, user-facing names of the missing features (Portuguese).
  final List<String> issues;

  bool get canRun => support != EffectSupport.unsupported;

  String get label => switch (support) {
    EffectSupport.compatible => 'Compatível',
    EffectSupport.partial => 'Parcial',
    EffectSupport.unsupported => 'Não suportado',
  };

  @override
  bool operator ==(Object other) =>
      other is EffectCompatibility &&
      other.support == support &&
      _sameStrings(other.issues, issues);

  @override
  int get hashCode => Object.hash(support, Object.hashAll(issues));
}

/// APIs that make an effect unusable with this runtime.
const _unsupported = <(String, String)>[
  ('engine.zone', 'captura de tela'),
  ('screenCapture', 'captura de tela'),
  ('desktopCapturer', 'captura de tela'),
  ('getImageData', 'leitura de pixels'),
];

/// APIs that work with a stub, degrading the effect.
const _partial = <(String, String)>[
  ('engine.audio', 'áudio (silêncio)'),
  ('drawImage', 'imagens'),
];

/// Analyzes the effect script (and its property types).
EffectCompatibility analyzeEffect(EffectSource effect) {
  final script = effect.script;
  final issues = <String>[];

  for (final (api, label) in _unsupported) {
    if (script.contains(api)) _append(issues, label);
  }
  for (final (api, label) in _partial) {
    if (script.contains(api)) _append(issues, label);
  }
  if (effect.properties.any((p) => p.type.toLowerCase() == 'audio')) {
    _append(issues, 'áudio (silêncio)');
  }

  const blocking = {'captura de tela', 'leitura de pixels'};
  if (issues.any(blocking.contains)) {
    return EffectCompatibility(EffectSupport.unsupported, issues);
  }
  return EffectCompatibility(
    issues.isEmpty ? EffectSupport.compatible : EffectSupport.partial,
    issues,
  );
}

void _append(List<String> list, String value) {
  if (!list.contains(value)) list.add(value);
}

bool _sameStrings(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
