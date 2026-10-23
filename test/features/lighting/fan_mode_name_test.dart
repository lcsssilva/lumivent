import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/lighting/domain/fan_mode_name.dart';
import 'package:lumivent/features/lighting/domain/lighting_config.dart';

void main() {
  test('fanModeBase strips only a trailing scope suffix', () {
    expect(fanModeBase('Wave'), 'Wave');
    expect(fanModeBase('Wave_Inner'), 'Wave');
    expect(fanModeBase('Wave_Outer'), 'Wave');
    expect(fanModeBase('Runway_Merge'), 'Runway');
    expect(fanModeBase('Inner'), 'Inner');
  });

  test('fanModeName appends the suffix text', () {
    expect(fanModeName('Wave'), 'Wave');
    expect(fanModeName('Wave', FanModeSuffix.inner), 'Wave_Inner');
    expect(fanModeName('Wave', FanModeSuffix.outer), 'Wave_Outer');
    expect(fanModeName('Runway', FanModeSuffix.merge), 'Runway_Merge');
  });

  test('normalizeMergeBase accepts the base and the merge name', () {
    const bases = ['Rainbow', 'Runway'];
    expect(normalizeMergeBase('Rainbow', bases), 'Rainbow');
    expect(normalizeMergeBase('Rainbow_Merge', bases), 'Rainbow');
    expect(normalizeMergeBase('Wave', bases), defaultMergeBase);
    expect(normalizeMergeBase('Rainbow_Inner', bases), defaultMergeBase);
  });

  test('convertFanModeScope keeps the effect or falls back to StaticColor', () {
    bool known(String n) => const {
      'Wave',
      'Wave_Inner',
      'StaticColor',
      'StaticColor_Inner',
      'PacMan_Inner',
    }.contains(n);

    String convert(String name, Alv2Scope to) =>
        convertFanModeScope(name, to, isKnown: known);

    expect(convert('Wave', Alv2Scope.innerOuter), 'Wave_Inner');
    expect(convert('Wave_Inner', Alv2Scope.whole), 'Wave');
    expect(convert('PacMan_Inner', Alv2Scope.whole), 'StaticColor');
    expect(convert('Wave_Outer', Alv2Scope.innerOuter), 'Wave_Inner');
    expect(convert('Unknown', Alv2Scope.innerOuter), 'StaticColor_Inner');
  });

  test('colorAt falls back to the factory defaults and cycles', () {
    const config = Alv2HardwareConfig(colors: []);
    final defaults = Alv2HardwareConfig.defaultColors;
    expect(config.colorAt(0), defaults[0]);
    expect(config.colorAt(defaults.length), defaults[0]);
    expect(config.colorAt(1), defaults[1 % defaults.length]);
  });
}
