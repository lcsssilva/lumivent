import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/explore/application/effect_filter.dart';
import 'package:lumivent/features/lighting/domain/effect_compat.dart';
import 'package:lumivent/features/lighting/domain/effect_meta.dart';
import 'package:lumivent/features/lighting/domain/installed_effect.dart';

EffectSource _source() =>
    EffectSource(title: 'Teste', properties: [], script: 'var a = 1;');

InstalledEffect _effect(String id, {List<String> tags = const []}) =>
    InstalledEffect(
      id: id,
      title: id,
      tags: tags,
      source: _source(),
      compatibility: EffectCompatibility(EffectSupport.compatible, const []),
    );

void main() {
  test('tag filter matches an effect whose stored tag has spaces', () {
    final effect = _effect('pro', tags: [' Pro']);
    final filter = EffectFilter(tag: 'Pro');

    expect(availableTags([effect]), contains('Pro'));
    expect(filter.matches(effect), isTrue);
    expect(filterEffects([effect], filter), [effect]);
  });

  test('tag filter ignores surrounding spaces on the wanted tag', () {
    final effect = _effect('pro', tags: ['Pro']);

    expect(EffectFilter(tag: ' Pro ').matches(effect), isTrue);
  });
}
