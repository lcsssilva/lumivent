import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/devices/devices.dart'
    show Alv2LightMode, Alv2LightScope;
import 'package:lumivent/features/lighting/domain/hardware_mode/fan_hardware_mode.dart';
import 'package:lumivent/features/lighting/domain/hardware_mode/fan_mode_name.dart';
import 'package:lumivent/features/lighting/infrastructure/alv2_fan_hardware_modes.dart';

void main() {
  const modes = [
    FanHardwareMode(name: 'Wave', hasSpeed: true, colorCount: 1),
    FanHardwareMode(name: 'Wave_Inner', scope: FanModeSuffix.inner),
    FanHardwareMode(name: 'Rainbow'),
    FanHardwareMode(name: 'Runway_Merge', scope: FanModeSuffix.merge),
    FanHardwareMode(name: 'Wave_Merge', scope: FanModeSuffix.merge),
  ];

  test('byName finds a mode or returns null', () {
    expect(modes.byName('Wave')!.colorCount, 1);
    expect(modes.byName('Wave_Inner')!.scope, FanModeSuffix.inner);
    expect(modes.byName('Unknown'), isNull);
  });

  test('namesOf keeps the table order of one scope', () {
    expect(modes.namesOf(null), ['Wave', 'Rainbow']);
    expect(modes.namesOf(FanModeSuffix.inner), ['Wave_Inner']);
    expect(modes.namesOf(FanModeSuffix.outer), isEmpty);
  });

  test('mergeBases strips the merge suffix', () {
    expect(modes.mergeBases, ['Runway', 'Wave']);
  });

  test('the AL V2 table maps every driver mode without its codes', () {
    expect(alv2FanHardwareModes, hasLength(Alv2LightMode.values.length));
    for (final (i, driver) in Alv2LightMode.values.indexed) {
      final mode = alv2FanHardwareModes[i];
      expect(mode.name, driver.firmwareName);
      expect(mode.hasSpeed, driver.hasSpeed);
      expect(mode.hasDirection, driver.hasDirection);
      expect(mode.colorCount, driver.colorCount);
      expect(mode.scope, switch (driver.scope) {
        Alv2LightScope.whole => null,
        Alv2LightScope.inner => FanModeSuffix.inner,
        Alv2LightScope.outer => FanModeSuffix.outer,
        Alv2LightScope.merge => FanModeSuffix.merge,
      });
    }
    expect(alv2FanHardwareModes.mergeBases, contains(defaultMergeBase));
  });
}
