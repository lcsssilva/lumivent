// Lighting module domain (pure Dart): native effects, evaluated per LED.
//
// Parameters follow the HTML effects' `<meta property>` types so the phase 5
// UI generates the controls the same way as for the installed effects.

import 'dart:math' as math;

import 'hardware_timing.dart';
import 'led_layout.dart';
import 'rgb.dart';

enum EffectParamType { number, color, boolean, combobox, hue }

/// Effect parameter declaration.
class EffectParam {
  const EffectParam.number(
    this.id,
    this.label, {
    required double this.min,
    required double this.max,
    required double this.defaultValue,
  }) : type = EffectParamType.number,
       options = const [];

  const EffectParam.hue(this.id, this.label, {double this.defaultValue = 0})
    : type = EffectParamType.hue,
      min = 0,
      max = 360,
      options = const [];

  /// [defaultValue] in `#RRGGBB`.
  const EffectParam.color(
    this.id,
    this.label, {
    required String this.defaultValue,
  }) : type = EffectParamType.color,
       min = null,
       max = null,
       options = const [];

  const EffectParam.boolean(
    this.id,
    this.label, {
    bool this.defaultValue = false,
  }) : type = EffectParamType.boolean,
       min = null,
       max = null,
       options = const [];

  const EffectParam.combobox(
    this.id,
    this.label, {
    required this.options,
    required String this.defaultValue,
  }) : type = EffectParamType.combobox,
       min = null,
       max = null;

  final String id;
  final String label;
  final EffectParamType type;
  final double? min, max;

  /// `double` (number/hue), `String` `#RRGGBB` (color), `bool` or `String`.
  final Object defaultValue;
  final List<String> options;

  /// Valid value for [raw]; default if missing, wrongly typed, or (for numbers)
  /// non-finite. Numbers are clamped to min..max.
  Object resolve(Object? raw) {
    switch (type) {
      case EffectParamType.number:
      case EffectParamType.hue:
        final n = raw is num
            ? raw.toDouble()
            : (raw is String ? double.tryParse(raw) : null);
        if (n == null || !n.isFinite) return defaultValue;
        return n.clamp(min!, max!);
      case EffectParamType.color:
        final c = raw is String ? Rgb.parse(raw) : null;
        return (c ?? Rgb.parse(defaultValue as String)!).toHex();
      case EffectParamType.boolean:
        if (raw is bool) return raw;
        if (raw is num) return raw != 0;
        return defaultValue;
      case EffectParamType.combobox:
        return raw is String && options.contains(raw) ? raw : defaultValue;
    }
  }
}

/// Validated parameter values for an effect.
class EffectValues {
  EffectValues(List<EffectParam> params, [Map<String, Object?> raw = const {}])
    : _v = {
        for (final p in params)
          p.id: p.type == EffectParamType.color
              ? Rgb.parse(p.resolve(raw[p.id]) as String)!
              : p.resolve(raw[p.id]),
      };

  final Map<String, Object> _v;

  double number(String id) => _v[id] as double;
  Rgb color(String id) => _v[id] as Rgb;
  bool boolean(String id) => _v[id] as bool;
  String option(String id) => _v[id] as String;
}

typedef EffectFn = Rgb Function(double x, double y, double t, EffectValues v);

/// Native effect: [colorAt] returns the LED color in (x, y) of the canvas
/// (0..320 × 0..200) at time [t] (seconds).
class NativeEffect {
  const NativeEffect(this.id, this.name, this.params, this._fn);

  final String id;
  final String name;
  final List<EffectParam> params;
  final EffectFn _fn;

  Rgb colorAt(double x, double y, double t, EffectValues v) => _fn(x, y, t, v);

  EffectValues valuesFrom(Map<String, Object?> raw) =>
      EffectValues(params, raw);
}

const _directionOptions = ['Esquerda', 'Direita', 'Cima', 'Baixo'];

const _speed = EffectParam.number(
  'speed',
  'Velocidade',
  min: 1,
  max: 100,
  defaultValue: 30,
);
const _waveSize = EffectParam.number(
  'size',
  'Tamanho da onda',
  min: 20,
  max: 640,
  defaultValue: 160,
);
const _direction = EffectParam.combobox(
  'direction',
  'Direção',
  options: _directionOptions,
  defaultValue: 'Direita',
);

/// Distance along the movement direction.
double _along(String dir, double x, double y) => switch (dir) {
  'Esquerda' => -x,
  'Cima' => -y,
  'Baixo' => y,
  _ => x,
};

double _cos2pi(double u) => math.cos(2 * math.pi * u);

final nativeEffects = List<NativeEffect>.unmodifiable([
  NativeEffect('solid', 'Cor sólida', const [
    EffectParam.color('color', 'Cor', defaultValue: '#FF0000'),
  ], (x, y, t, v) => v.color('color')),
  NativeEffect('spectrum', 'Ciclo de cores', const [
    _speed,
  ], (x, y, t, v) => Rgb.fromHsv(t * v.number('speed') * 3.6, 1, 1)),
  NativeEffect(
    'rainbowWave',
    'Onda arco-íris',
    const [_speed, _direction, _waveSize],
    (x, y, t, v) {
      final d = _along(v.option('direction'), x, y);
      final phase = d / v.number('size') - t * v.number('speed') / 100;
      return Rgb.fromHsv(phase * 360, 1, 1);
    },
  ),
  NativeEffect(
    'breathing',
    'Respiração',
    const [EffectParam.color('color', 'Cor', defaultValue: '#00BFFF'), _speed],
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
    'Onda de duas cores',
    const [
      EffectParam.color('color', 'Cor 1', defaultValue: '#FF0080'),
      EffectParam.color('color2', 'Cor 2', defaultValue: '#0080FF'),
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
    'Varredura',
    const [
      EffectParam.color('color', 'Cor', defaultValue: '#FF0000'),
      EffectParam.color('background', 'Fundo', defaultValue: '#000000'),
      _speed,
      EffectParam.number(
        'width',
        'Largura',
        min: 5,
        max: 320,
        defaultValue: 60,
      ),
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

NativeEffect? nativeEffectById(String id) =>
    nativeEffects.where((e) => e.id == id).firstOrNull;
