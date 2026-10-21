import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/explore/application/effect_filter.dart';
import 'package:lumivent/features/lighting/domain/effect_compat.dart';
import 'package:lumivent/features/lighting/domain/effect_meta.dart';
import 'package:lumivent/features/lighting/domain/effect_runtime.dart';
import 'package:lumivent/features/lighting/domain/effect_sampling.dart';
import 'package:lumivent/features/lighting/domain/installed_effect.dart';
import 'package:lumivent/features/lighting/domain/led_layout.dart';
import 'package:lumivent/features/lighting/domain/light_device.dart';
import 'package:lumivent/features/lighting/domain/lighting_config.dart';
import 'package:lumivent/features/lighting/domain/rgb.dart';
import 'package:lumivent/features/lighting/infrastructure/html_effects/canvas_buffer.dart';

EffectSource source({
  String script = 'var a = 1;',
  List<EffectProperty> properties = const [],
}) => EffectSource(title: 'Teste', properties: properties, script: script);

InstalledEffect installed({
  String id = 'efeito',
  String title = 'Efeito',
  String? publisher = 'Autor',
  List<String> tags = const [],
  EffectCompatibility? compatibility,
  String script = 'var a = 1;',
}) => InstalledEffect(
  id: id,
  title: title,
  source: source(script: script),
  compatibility:
      compatibility ?? const EffectCompatibility(EffectSupport.compatible, []),
  publisher: publisher,
  tags: tags,
);

void main() {
  group('EffectProperty.resolve', () {
    final number = EffectProperty(
      name: 'speed',
      type: 'number',
      min: 10,
      max: 80,
      defaultValue: '50',
    );

    test('clamps numbers and falls back on invalid values', () {
      expect(number.resolve(null), 50);
      expect(number.resolve(90), 80);
      expect(number.resolve(-3), 10);
      expect(number.resolve('nope'), 50);
      expect(number.resolve(33.5), 33.5);
    });

    test('boolean, combobox, color, and text defaults', () {
      final flag = EffectProperty(
        name: 'on',
        type: 'boolean',
        defaultValue: '1',
      );
      expect(flag.resolve(null), true);
      expect(flag.resolve(false), false);
      expect(flag.resolve(0), false);

      final mode = EffectProperty(
        name: 'mode',
        type: 'combobox',
        values: const ['A', 'B'],
        defaultValue: 'B',
      );
      expect(mode.resolve(null), 'B');
      expect(mode.resolve('A'), 'A');
      expect(mode.resolve('Z'), 'B');

      final color = EffectProperty(
        name: 'color',
        type: 'color',
        defaultValue: '#f00',
      );
      expect(color.resolve(null), '#FF0000');
      expect(color.resolve('#0080ff'), '#0080FF');
      expect(color.resolve('nope'), '#FF0000');

      final text = EffectProperty(
        name: 'label',
        type: 'textfield',
        defaultValue: 'oi',
      );
      expect(text.resolve('tudo bem'), 'tudo bem');
      expect(text.resolve(3), 'oi');
    });
  });

  group('analyzeEffect', () {
    test('compatible when only the supported API is used', () {
      final c = analyzeEffect(source(script: 'engine.getSensorValue("cpu")'));
      expect(c.support, EffectSupport.compatible);
      expect(c.issues, isEmpty);
      expect(c.canRun, isTrue);
      expect(c.label, 'Compatível');
    });

    test('partial for audio, deduplicated with the Audio property', () {
      final c = analyzeEffect(
        source(
          script: 'if (engine.audio.level > -40) {}',
          properties: [
            EffectProperty(name: 'mode', type: 'Audio', defaultValue: 'Level'),
          ],
        ),
      );
      expect(c.support, EffectSupport.partial);
      expect(c.issues, ['áudio (silêncio)']);
      expect(c.canRun, isTrue);
      expect(c.label, 'Parcial');
    });

    test('unsupported for screen capture or pixel reads', () {
      final zone = analyzeEffect(source(script: 'engine.zone.hue[0]'));
      expect(zone.support, EffectSupport.unsupported);
      expect(zone.issues, ['captura de tela']);
      expect(zone.canRun, isFalse);

      final pixels = analyzeEffect(source(script: 'ctx.getImageData(0,0,1,1)'));
      expect(pixels.support, EffectSupport.unsupported);
      expect(pixels.issues, ['leitura de pixels']);
    });

    test('blocking issue wins over a partial one', () {
      final c = analyzeEffect(
        source(script: 'engine.audio.level + engine.zone.hue[0]'),
      );
      expect(c.support, EffectSupport.unsupported);
      expect(c.issues, containsAll(['áudio (silêncio)', 'captura de tela']));
    });
  });

  group('sampleEffectFrame', () {
    EffectFrame solid(int r, int g, int b) {
      final rgba = Uint8List(canvasWidth * canvasHeight * 4);
      for (var i = 0; i < rgba.length; i += 4) {
        rgba[i] = r;
        rgba[i + 1] = g;
        rgba[i + 2] = b;
        rgba[i + 3] = 255;
      }
      return EffectFrame(canvasWidth, canvasHeight, rgba);
    }

    test('samples every enabled canvas device in driver order', () {
      final cfg = LightingConfig();
      final colors = sampleEffectFrame(cfg, solid(12, 34, 56));
      expect(colors.keys, contains(LightDeviceId.chassis));
      expect(colors.keys, contains(LightDeviceId.motherboard));
      expect(colors.keys, contains(LightDeviceId.ram1));
      // The GPU has a single color (the average of its rectangle).
      expect(colors[LightDeviceId.gpu], [const Rgb(12, 34, 56)]);
      for (final entry in colors.entries) {
        if (entry.key == LightDeviceId.gpu) continue;
        final expected = ledLayoutFor(
          entry.key,
          fanQuantity: cfg.fansOf(entry.key),
        ).length;
        expect(entry.value, hasLength(expected), reason: '${entry.key}');
        for (final c in entry.value) {
          expect(c, const Rgb(12, 34, 56));
        }
      }
    });

    test('skips fixed/hardware/disabled devices and the ARGB off state', () {
      final fixed = LightingConfig(
        devices: {
          LightDeviceId.chassis: DeviceLightConfig.defaults(
            LightDeviceId.chassis,
          ).copyWith(mode: LightMode.fixed),
          LightDeviceId.ram1: DeviceLightConfig.defaults(LightDeviceId.ram1)
              .copyWith(enabled: false),
        },
      );
      final colors = sampleEffectFrame(fixed, solid(1, 2, 3));
      expect(colors.keys, isNot(contains(LightDeviceId.chassis)));
      expect(colors.keys, isNot(contains(LightDeviceId.ram1)));

      final off = sampleEffectFrame(
        LightingConfig(argbOff: true),
        solid(1, 2, 3),
      );
      expect(off, isEmpty);
    });

    test('reads the mapped pixel of a gradient frame', () {
      final rgba = Uint8List(canvasWidth * canvasHeight * 4);
      for (var y = 0; y < canvasHeight; y++) {
        for (var x = 0; x < canvasWidth; x++) {
          final o = (y * canvasWidth + x) * 4;
          rgba[o] = x < canvasWidth ~/ 2 ? 255 : 0;
          rgba[o + 1] = 0;
          rgba[o + 2] = x < canvasWidth ~/ 2 ? 0 : 255;
          rgba[o + 3] = 255;
        }
      }
      final colors = sampleEffectFrame(
        LightingConfig(),
        EffectFrame(canvasWidth, canvasHeight, rgba),
      );
      // Chassis LED 0 is on the right (D_LED1), the last one on the left.
      final chassis = colors[LightDeviceId.chassis]!;
      expect(chassis.first, const Rgb(0, 0, 255));
      expect(chassis.last, const Rgb(255, 0, 0));
    });
  });

  group('EffectFilter', () {
    final effects = [
      installed(
        id: 'rainbow',
        title: 'Rainbow',
        publisher: 'Autor Y',
        tags: const ['Basic', 'Color'],
      ),
      installed(
        id: 'neon',
        title: 'Neon Shift',
        publisher: 'Autor X',
        tags: const ['Advanced'],
      ),
      installed(
        id: 'audio',
        title: 'Audio Bars',
        publisher: 'Autor X',
        tags: const ['Audio'],
        compatibility: const EffectCompatibility(EffectSupport.partial, [
          'áudio (silêncio)',
        ]),
      ),
    ];

    test('search covers title, publisher, description, and tags', () {
      expect(filterEffects(effects, const EffectFilter(query: 'rain')), [
        effects[0],
      ]);
      expect(filterEffects(effects, const EffectFilter(query: 'autor x')), [
        effects[1],
        effects[2],
      ]);
      expect(filterEffects(effects, const EffectFilter(query: 'advanced')), [
        effects[1],
      ]);
    });

    test('support, tag, and publisher combine', () {
      expect(
        filterEffects(effects, const EffectFilter(tag: 'Audio')).single.id,
        'audio',
      );
      expect(
        filterEffects(
          effects,
          const EffectFilter(publisher: 'Autor X', tag: 'Advanced'),
        ).single.id,
        'neon',
      );
      expect(
        filterEffects(
          effects,
          const EffectFilter(support: SupportFilter.partial),
        ).single.id,
        'audio',
      );
      expect(
        filterEffects(
          effects,
          const EffectFilter(support: SupportFilter.unsupported),
        ),
        isEmpty,
      );
    });

    test('lists sorted tags and publishers', () {
      expect(availableTags(effects), ['Advanced', 'Audio', 'Basic', 'Color']);
      expect(availablePublishers(effects), ['Autor X', 'Autor Y']);
    });
  });

  group('canvas binary protocol', () {
    /// Same layout as the JS shim: opcode, count, then tagged arguments.
    Uint8List encode(List<(int, List<Object>)> ops) {
      final bytes = BytesBuilder();
      for (final (code, args) in ops) {
        bytes.addByte(code);
        bytes.addByte(args.length);
        for (final arg in args) {
          if (arg is num) {
            final data = ByteData(5)
              ..setUint8(0, 0)
              ..setFloat32(1, arg.toDouble(), Endian.little);
            bytes.add(data.buffer.asUint8List());
          } else if (arg is GradientRef) {
            final data = ByteData(5)
              ..setUint8(0, 2)
              ..setFloat32(1, arg.id.toDouble(), Endian.little);
            bytes.add(data.buffer.asUint8List());
          } else {
            final text = arg as String;
            final utf8 = Uint8List.fromList(text.codeUnits);
            final data = ByteData(3)
              ..setUint8(0, 1)
              ..setUint16(1, utf8.length, Endian.little);
            bytes
              ..add(data.buffer.asUint8List())
              ..add(utf8);
          }
        }
      }
      return bytes.takeBytes();
    }

    test('decodes numbers, strings, and gradient references', () {
      final buffer = CanvasCommandBuffer(
        encode([
          (CanvasOp.fillRect, [1.0, 2.5, 3.0, 4.0]),
          (CanvasOp.fillStyle, ['#ff0000']),
          (CanvasOp.linearGradient, [7.0, 0.0, 0.0, 10.0, 0.0]),
          (CanvasOp.colorStop, [7.0, 0.5, 'rgba(0,0,0,1)']),
          (CanvasOp.fillStyle, [GradientRef(7)]),
        ]),
      );
      expect(buffer.next(), isTrue);
      expect(buffer.opcode, CanvasOp.fillRect);
      expect(buffer.argCount, 4);
      expect(buffer.number(1), 2.5);
      expect(buffer.next(), isTrue);
      expect(buffer.opcode, CanvasOp.fillStyle);
      expect(buffer.text(0), '#ff0000');
      expect(buffer.next(), isTrue);
      expect(buffer.opcode, CanvasOp.linearGradient);
      expect(buffer.number(0), 7);
      expect(buffer.next(), isTrue);
      expect(buffer.text(2), 'rgba(0,0,0,1)');
      expect(buffer.next(), isTrue);
      expect(buffer.isGradient(0), isTrue);
      expect(buffer.number(0), 7);
      expect(buffer.next(), isFalse);
      expect(buffer.count, 5);
    });
  });
}

class GradientRef {
  const GradientRef(this.id);
  final int id;
}
