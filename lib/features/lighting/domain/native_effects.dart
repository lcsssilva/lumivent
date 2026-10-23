// Lighting module domain (pure Dart): native effects, evaluated per LED.
//
// Parameters follow the HTML effects' `<meta property>` types so the phase 5
// UI generates the controls the same way as for the installed effects.

import 'dart:math' as math;

import 'hardware_timing.dart';
import 'led_layout.dart';
import 'rgb.dart';
import 'effect_values.dart';
import 'native_effect.dart';
import 'effect_param.dart';

typedef EffectFn = Rgb Function(double x, double y, double t, EffectValues v);

const _directionOptions = ['Left', 'Right', 'Up', 'Down'];

const _speed = EffectParam.number(
  'speed',
  'Speed',
  min: 1,
  max: 100,
  defaultValue: 30,
);
const _waveSize = EffectParam.number(
  'size',
  'Wave size',
  min: 20,
  max: 640,
  defaultValue: 160,
);
const _direction = EffectParam.combobox(
  'direction',
  'Direction',
  options: _directionOptions,
  defaultValue: 'Right',
);

/// Distance along the movement direction.
double _along(String dir, double x, double y) => switch (dir) {
  'Left' => -x,
  'Up' => -y,
  'Down' => y,
  _ => x,
};

double _cos2pi(double u) => math.cos(2 * math.pi * u);

final nativeEffects = List<NativeEffect>.unmodifiable([
  NativeEffect('solid', 'Solid color', const [
    EffectParam.color('color', 'Color', defaultValue: '#FF0000'),
  ], (x, y, t, v) => v.color('color')),
  NativeEffect('spectrum', 'Color cycle', const [
    _speed,
  ], (x, y, t, v) => Rgb.fromHsv(t * v.number('speed') * 3.6, 1, 1)),
  NativeEffect(
    'rainbowWave',
    'Rainbow wave',
    const [_speed, _direction, _waveSize],
    (x, y, t, v) {
      final d = _along(v.option('direction'), x, y);
      final phase = d / v.number('size') - t * v.number('speed') / 100;
      return Rgb.fromHsv(phase * 360, 1, 1);
    },
  ),
  NativeEffect(
    breathingEffectId,
    'Breathing',
    const [
      EffectParam.color('color', 'Color', defaultValue: '#00BFFF'),
      _speed,
    ],
    (x, y, t, v) {
      // Same period as the firmware `Breathing` of the chosen speed, so the
      // case, board and RAM breathe with the fans (phase comes from the
      // engine, which knows when the hardware mode was sent).
      final period =
          alv2BreathingPeriod(v.number('speed')).inMicroseconds / 1e6;
      final k = 0.5 - 0.5 * _cos2pi(t / period);
      return v.color('color').scaled(k);
    },
  ),
  NativeEffect(
    'colorWave',
    'Two-color wave',
    const [
      EffectParam.color('color', 'Color 1', defaultValue: '#FF0080'),
      EffectParam.color('color2', 'Color 2', defaultValue: '#0080FF'),
      _speed,
      _direction,
      _waveSize,
    ],
    (x, y, t, v) {
      final d = _along(v.option('direction'), x, y);
      final phase = d / v.number('size') - t * v.number('speed') / 100;
      return Rgb.lerp(
        v.color('color'),
        v.color('color2'),
        0.5 - 0.5 * _cos2pi(phase),
      );
    },
  ),
  NativeEffect(
    'scanner',
    'Scanner',
    const [
      EffectParam.color('color', 'Color', defaultValue: '#FF0000'),
      EffectParam.color('background', 'Background', defaultValue: '#000000'),
      _speed,
      EffectParam.number('width', 'Width', min: 5, max: 320, defaultValue: 60),
    ],
    (x, y, t, v) {
      // Triangle back and forth: 2-second period at speed 50.
      final u = (t * v.number('speed') / 100) % 1.0;
      final pos = canvasWidth * (1 - (2 * u - 1).abs());
      final k = 1 - (x - pos).abs() / (v.number('width') / 2);
      return Rgb.lerp(v.color('background'), v.color('color'), k);
    },
  ),
]);

const defaultEffectId = 'rainbowWave';

/// Id of the Breathing effect, whose canvas follows the firmware clock when
/// the fans run [breathingFirmwareMode] (see `hardware_equivalent.dart`).
const breathingEffectId = 'breathing';

NativeEffect? nativeEffectById(String id) =>
    nativeEffects.where((e) => e.id == id).firstOrNull;
