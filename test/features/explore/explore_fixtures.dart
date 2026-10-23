import 'package:lumivent/features/lighting/domain/effects/effect_compatibility.dart';
import 'package:lumivent/features/lighting/domain/effects/effect_source.dart';
import 'package:lumivent/features/lighting/domain/effects/installed_effect.dart';

EffectSource _source() =>
    EffectSource(title: 'Teste', properties: [], script: 'var a = 1;');

/// An installed effect with the given catalog data.
InstalledEffect installedEffect(
  String id,
  String title, {
  String? publisher = 'Autor',
  List<String> tags = const [],
  EffectSupport support = EffectSupport.compatible,
  List<EffectIssue> issues = const [],
}) => InstalledEffect(
  id: id,
  title: title,
  publisher: publisher,
  tags: tags,
  source: _source(),
  compatibility: EffectCompatibility(support, issues),
);
