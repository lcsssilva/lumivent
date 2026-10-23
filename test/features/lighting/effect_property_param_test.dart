import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/lighting/domain/effect_meta.dart';
import 'package:lumivent/features/lighting/domain/effect_property_param.dart';
import 'package:lumivent/features/lighting/domain/native_effects.dart';

void main() {
  test('number keeps its range and clamps the default into it', () {
    final param = EffectProperty(
      name: 'speed',
      type: 'number',
      label: 'Speed',
      min: 1,
      max: 10,
      defaultValue: '50',
    ).toParam()!;
    expect(param.type, EffectParamType.number);
    expect(param.label, 'Speed');
    expect((param.min, param.max), (1.0, 10.0));
    expect(param.defaultValue, 10.0);
  });

  test('number with an empty range gets a unit-wide range', () {
    final param = EffectProperty(
      name: 'n',
      type: 'number',
      min: 5,
      max: 5,
    ).toParam()!;
    expect(param.label, 'n');
    expect((param.min, param.max), (5.0, 6.0));
    expect(param.defaultValue, 5.0);
  });

  test('hue, color, and boolean use their defaults', () {
    expect(
      EffectProperty(
        name: 'h',
        type: 'hue',
        defaultValue: '120',
      ).toParam()!.defaultValue,
      120.0,
    );
    expect(
      EffectProperty(name: 'c', type: 'color').toParam()!.defaultValue,
      '#FFFFFF',
    );
    expect(
      EffectProperty(
        name: 'c',
        type: 'color',
        defaultValue: '#102030',
      ).toParam()!.defaultValue,
      '#102030',
    );
    expect(
      EffectProperty(
        name: 'b',
        type: 'boolean',
        defaultValue: 'true',
      ).toParam()!.defaultValue,
      true,
    );
  });

  test('combobox falls back to its first option', () {
    final param = EffectProperty(
      name: 'mode',
      type: 'combobox',
      values: const ['a', 'b'],
      defaultValue: 'zzz',
    ).toParam()!;
    expect(param.options, ['a', 'b']);
    expect(param.defaultValue, 'a');
  });

  test('textfield, sensor, and unknown types have no generated control', () {
    for (final type in ['textfield', 'sensor', 'other']) {
      expect(EffectProperty(name: 'x', type: type).toParam(), isNull);
    }
  });
}
