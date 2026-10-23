import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/lighting/domain/hardware_mode/hardware_timing.dart';
import 'package:lumivent/features/lighting/domain/native_effects/native_effects.dart';
import 'package:lumivent/features/lighting/domain/effects/effect_param.dart';
import 'package:lumivent/features/lighting/domain/effects/effect_values.dart';
import 'package:lumivent/features/lighting/domain/rgb.dart';

void main() {
  test('registry', () {
    expect(nativeEffects.map((e) => e.id), [
      'solid',
      'spectrum',
      'rainbowWave',
      'breathing',
      'colorWave',
      'scanner',
    ]);
    expect(nativeEffectById('scanner')!.name, 'Scanner');
    expect(nativeEffectById('nada'), isNull);
    final dir = nativeEffectById('rainbowWave')!.params
        .firstWhere((p) => p.id == 'direction');
    expect(dir.type, EffectParamType.combobox);
    expect(dir.options, ['Left', 'Right', 'Up', 'Down']);
    // Legacy Portuguese values saved by older versions keep working.
    expect(
      nativeEffectById('rainbowWave')!
          .valuesFrom({'direction': 'Esquerda'})
          .option('direction'),
      'Left',
    );
  });

  test('deterministic effects', () {
    for (final e in nativeEffects) {
      final v = e.valuesFrom(const {});
      expect(
        e.colorAt(100, 50, 1.5, v),
        e.colorAt(100, 50, 1.5, v),
        reason: e.id,
      );
    }
  });

  test('solid returns the color', () {
    final e = nativeEffectById('solid')!;
    expect(
      e.colorAt(5, 5, 0, e.valuesFrom({'color': '#102030'})),
      const Rgb(16, 32, 48),
    );
  });

  test('spectrum varies with t', () {
    final e = nativeEffectById('spectrum')!;
    final v = e.valuesFrom(const {});
    expect(e.colorAt(0, 0, 0, v), isNot(e.colorAt(0, 0, 1, v)));
  });

  test('rainbowWave: direction and spacing', () {
    final e = nativeEffectById('rainbowWave')!;
    final r = e.valuesFrom({'direction': 'Direita'});
    final l = e.valuesFrom({'direction': 'Esquerda'});
    expect(e.colorAt(0, 0, 0, r), e.colorAt(0, 0, 0, l));
    expect(e.colorAt(40, 0, 0, r), isNot(e.colorAt(40, 0, 0, l)));
    expect(e.colorAt(40, 0, 0, r), isNot(e.colorAt(0, 0, 0, r)));
    // The wave moves to the right: the color of x=0 at t=0 appears further along at t>0.
    final c0 = e.colorAt(0, 0, 0, r);
    final moved = [for (var x = 0.0; x < 320; x += 1) x]
        .where((x) => e.colorAt(x, 0, 1, r) == c0);
    expect(moved.isNotEmpty && moved.first > 0, isTrue);
  });

  test('breathing uses the firmware period of the chosen speed', () {
    final e = nativeEffectById('breathing')!;
    final v = e.valuesFrom({'color': '#FF0000', 'speed': 50});
    final period = alv2BreathingPeriod(50);
    expect(e.colorAt(0, 0, 0, v), Rgb.black);
    expect(
      e.colorAt(0, 0, period.inMicroseconds / 1e6 / 2, v),
      const Rgb(255, 0, 0),
    );
    // One period later it is back to the start (dark), not a 2 s cycle.
    expect(e.colorAt(0, 0, period.inMicroseconds / 1e6, v), Rgb.black);
  });

  test('scanner: color at the peak, background far away', () {
    final e = nativeEffectById('scanner')!;
    final v = e.valuesFrom({
      'color': '#00FF00',
      'background': '#000010',
      'speed': 50,
      'width': 40,
    });
    expect(
      e.colorAt(160, 0, 0.5, v),
      const Rgb(0, 255, 0),
    ); // middle of the path
    expect(e.colorAt(0, 0, 0.5, v), const Rgb(0, 0, 16));
  });

  test('out-of-range or invalid values', () {
    final e = nativeEffectById('rainbowWave')!;
    final v = EffectValues(e.params, {
      'speed': 9999,
      'size': -4,
      'direction': 'Diagonal',
    });
    expect(v.number('speed'), 100);
    expect(v.number('size'), 20);
    expect(v.option('direction'), 'Right');
    final s = EffectValues(nativeEffectById('solid')!.params, {
      'color': 'lixo',
    });
    expect(s.color('color'), const Rgb(255, 0, 0));
    final b = EffectValues(
      const [EffectParam.boolean('b', 'B', defaultValue: true)],
      {'b': 'x'},
    );
    expect(b.boolean('b'), isTrue);
    for (final fx in nativeEffects) {
      final bad = fx.valuesFrom({for (final p in fx.params) p.id: double.nan});
      final c = fx.colorAt(-50, 900, -3, bad);
      expect(c.r, inInclusiveRange(0, 255));
    }
  });
}
