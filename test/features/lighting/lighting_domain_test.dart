import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/core/i18n/app_strings.dart';
import 'package:lumivent/features/lighting/domain/frame_composer.dart';
import 'package:lumivent/features/lighting/domain/led_layout.dart';
import 'package:lumivent/features/lighting/domain/light_device.dart';
import 'package:lumivent/features/lighting/domain/lighting_config.dart';
import 'package:lumivent/features/lighting/infrastructure/lighting_codec.dart';
import 'package:lumivent/features/lighting/domain/rgb.dart';
import 'package:lumivent/features/lighting/presentation/labels.dart';

void main() {
  group('Rgb', () {
    test('tolerant hex round trip', () {
      expect(const Rgb(255, 128, 0).toHex(), '#FF8000');
      expect(Rgb.parse('#ff8000'), const Rgb(255, 128, 0));
      expect(Rgb.parse('0f0'), const Rgb(0, 255, 0));
      expect(Rgb.parse('#12345'), isNull);
      expect(Rgb.parse('zzzzzz'), isNull);
      expect(Rgb.parse(null), isNull);
    });
    test('hsv', () {
      expect(Rgb.fromHsv(0, 1, 1), const Rgb(255, 0, 0));
      expect(Rgb.fromHsv(120, 1, 1), const Rgb(0, 255, 0));
      expect(Rgb.fromHsv(240, 1, 1), const Rgb(0, 0, 255));
      expect(Rgb.fromHsv(360, 1, 1), const Rgb(255, 0, 0));
      expect(Rgb.fromHsv(0, 0, 1), Rgb.white);
    });
    test('scaled and lerp', () {
      expect(const Rgb(255, 101, 3).scaled(0.5), const Rgb(127, 50, 1));
      expect(const Rgb(10, 10, 10).scaled(2), const Rgb(20, 20, 20));
      expect(const Rgb(200, 200, 200).scaled(-1), Rgb.black);
      expect(Rgb.lerp(Rgb.black, Rgb.white, 0.5), const Rgb(128, 128, 128));
    });
    test('maxChannel and toString', () {
      expect(const Rgb(1, 200, 7).maxChannel, 200);
      expect(Rgb.black.maxChannel, 0);
      expect(const Rgb(255, 128, 0).toString(), 'Rgb(#FF8000)');
    });
  });

  group('devices', () {
    test('accepted modes', () {
      expect(LightDeviceId.alv2Group1.supportedModes, LightMode.values.toSet());
      expect(
        LightDeviceId.motherboard.supportedModes,
        LightMode.values.toSet(),
      );
      expect(LightDeviceId.chassis.supportedModes, {
        LightMode.canvas,
        LightMode.fixed,
      });
      expect(LightDeviceId.ram2.accepts(LightMode.hardware), isFalse);
      expect(LightDeviceId.gpu.supportedModes, {
        LightMode.canvas,
        LightMode.hardware,
        LightMode.fixed,
      });
      expect(LightDeviceId.alv2Group3.hubGroup, 3);
      expect(LightDeviceId.chassis.hubGroup, isNull);
      expect(
        deviceLabel(AppStrings.pt, LightDeviceId.alv2Group2),
        'Fans · Grupo 2',
      );
    });
  });

  group('layout', () {
    test('LED count', () {
      expect(ledLayoutFor(LightDeviceId.alv2Group1, fanQuantity: 3).length, 60);
      expect(ledLayoutFor(LightDeviceId.alv2Group1, fanQuantity: 0).length, 0);
      expect(
        ledLayoutFor(LightDeviceId.alv2Group1, fanQuantity: 9).length,
        120,
      );
      expect(ledLayoutFor(LightDeviceId.chassis).length, 47);
      expect(ledLayoutFor(LightDeviceId.motherboard).length, 3);
      expect(ledLayoutFor(LightDeviceId.ram1).length, 12);
      expect(ledLayoutFor(LightDeviceId.gpu).length, 0);
      for (final id in LightDeviceId.values) {
        expect(
          ledLayoutFor(id, fanQuantity: 2).length,
          ledCountFor(id, fanQuantity: 2),
        );
      }
    });
    test('everything stays in [0,1]', () {
      for (final id in LightDeviceId.values) {
        for (final p in ledLayoutFor(id, fanQuantity: 6).leds) {
          expect(p.x, inInclusiveRange(0, 1));
          expect(p.y, inInclusiveRange(0, 1));
        }
      }
    });
    test(
      'fan: inner before outer, starts at the cable (left), counterclockwise',
      () {
        final l = ledLayoutFor(LightDeviceId.alv2Group1, fanQuantity: 1).leds;
        expect(l[0].x, lessThan(0.5)); // left, where the cable is
        expect(l[0].y, closeTo(0.5, 1e-9));
        expect(l[1].y, greaterThan(0.5)); // counterclockwise: next goes down
        expect((l[0].x - 0.5).abs(), closeTo(0.18, 1e-9));
        expect((l[8].x - 0.5).abs(), closeTo(0.42, 1e-9));
      },
    );
    test('case: index 0 on the right', () {
      final l = ledLayoutFor(LightDeviceId.chassis).leds;
      expect(l.first.x, 1);
      expect(l.last.x, 0);
      expect(ledLayoutFor(LightDeviceId.chassis).aspect, greaterThan(10));
    });
    test('default positions do not overlap and stay within the canvas', () {
      final ids = LightDeviceId.values;
      for (final a in ids) {
        final r = CanvasRect.defaultFor(a);
        expect(r.x, greaterThanOrEqualTo(0));
        expect(r.right, lessThanOrEqualTo(canvasWidth));
        expect(r.bottom, lessThanOrEqualTo(canvasHeight));
        for (final b in ids.where((b) => b != a)) {
          expect(
            r.overlaps(CanvasRect.defaultFor(b)),
            isFalse,
            reason: '$a x $b',
          );
        }
      }
    });
    test('map and clamp', () {
      const r = CanvasRect(300, 190, 100, 100);
      final (x, y) = r.map(const LedPoint(1, 1));
      expect(x, canvasWidth);
      expect(y, canvasHeight);
      final c = r.clamped();
      expect(c.right, lessThanOrEqualTo(canvasWidth));
      expect(c.bottom, lessThanOrEqualTo(canvasHeight));
    });
    test('CanvasRect copyWith, equality and toString', () {
      const r = CanvasRect(1, 2, 3, 4);
      expect(r.copyWith(x: 9), const CanvasRect(9, 2, 3, 4));
      expect(r, const CanvasRect(1, 2, 3, 4));
      expect(r.hashCode, const CanvasRect(1, 2, 3, 4).hashCode);
      expect(r.toString(), 'CanvasRect(1.0, 2.0, 3.0, 4.0)');
      expect(const LedPoint(0.5, 0.25).toString(), 'LedPoint(0.5, 0.25)');
    });
  });

  group('LightingConfig', () {
    test('defaults', () {
      final c = LightingConfig();
      expect(c.argbOff, isFalse);
      expect(c.brightness, 1);
      expect(c.offOnSleep, isTrue);
      expect(c.effectId, 'rainbowWave');
      expect(c.fanQuantity, [0, 3, 3, 1]);
      expect(c.device(LightDeviceId.gpu).enabled, isTrue);
      expect(c.alv2Hardware[1].mode, 'StaticColor');
      expect(c.alv2Hardware[1].colors.first, const Rgb(255, 0, 0));
      expect(c.boardZones.keys, [0x20, 0x22, 0x23]);
    });

    test('JSON round trip', () {
      final c =
          LightingConfig(
                argbOff: true,
                brightness: 0.4,
                offOnSleep: false,
                effectId: 'scanner',
                fanQuantity: const [0, 2, 6, 1],
                alv2Merge: true,
                alv2MergeMode: 'Rainbow',
              )
              .withEffectValue('scanner', 'width', 33.0)
              .withEffectValue('scanner', 'color', '#00FF00')
              .withDevice(
                LightDeviceId.chassis,
                LightingConfig()
                    .device(LightDeviceId.chassis)
                    .copyWith(
                      mode: LightMode.fixed,
                      fixedColor: const Rgb(1, 2, 3),
                    ),
              )
              .copyWith(
                alv2Hardware: [
                  for (var i = 0; i < 4; i++)
                    Alv2HardwareConfig(
                      scope: Alv2Scope.innerOuter,
                      mode: 'StaticColor_Inner',
                      speed: i,
                      colors: const [Rgb(9, 8, 7)],
                    ),
                ],
                boardZones: {
                  0x22: const BoardZoneConfig(
                    mode: BoardEffectMode.wave,
                    color: Rgb(5, 6, 7),
                    speed: 1,
                    brightness: 2,
                  ),
                },
              );
      final back = decodeLightingConfig(encodeLightingConfig(c));
      expect(back, c);
      expect(back.hashCode, c.hashCode);
      expect(LightingConfig(), isNot(c));
    });

    test('merge order: default, round trip and invalid values', () {
      expect(LightingConfig().alv2MergeOrder, [0, 1, 2, 3]);
      final c = LightingConfig(alv2MergeOrder: const [0, 1, 3, 2]);
      final back = decodeLightingConfig(encodeLightingConfig(c));
      expect(back.alv2MergeOrder, [0, 1, 3, 2]);
      expect(back, c);
      expect(c, isNot(LightingConfig()));
      // Repeated group, group 0 moved, short, wrong type: all fall back.
      for (final bad in <Object>[
        [0, 1, 1, 2],
        [1, 0, 2, 3],
        [0, 1, 2],
        [0, 1, 2, '3'],
        '0123',
      ]) {
        expect(decodeLightingConfig({'alv2MergeOrder': bad}).alv2MergeOrder, [
          0,
          1,
          2,
          3,
        ], reason: '$bad');
      }
    });

    test('legacy configuration', () {
      final c = decodeLightingConfig({'argbOff': true});
      expect(c.argbOff, isTrue);
      expect(c.brightness, 1);
      expect(c.fanQuantity, [0, 3, 3, 1]);
    });

    test('wrong and unknown types are tolerated', () {
      final c = decodeLightingConfig({
        'argbOff': 'sim',
        'brightness': 7,
        'offOnSleep': 3,
        'effectId': 42,
        'effectValues': {
          'solid': 'x',
          'scanner': {
            'width': 'a',
            'ok': 1,
            'bad': [1],
          },
        },
        'fanQuantity': [1, 99, 'x'],
        'alv2Hardware': 'x',
        'devices': {
          'gpu': {'enabled': true, 'mode': 'canvas'},
          'chassis': {
            'mode': 'hardware',
            'enabled': 'x',
            'fixedColor': 'nada',
            'placement': {'x': 'a', 'w': -5},
          },
          'tv': {'enabled': false},
        },
        'boardZones': {
          '0x22': {'mode': 'xx', 'speed': 99},
        },
      });
      expect(c.argbOff, isFalse);
      expect(c.brightness, 1);
      expect(c.offOnSleep, isTrue);
      expect(c.effectId, 'rainbowWave');
      expect(c.effectValues.containsKey('solid'), isFalse);
      expect(c.effectValues['scanner'], {
        'width': 'a',
        'ok': 1,
      }); // list discarded; 'a' uses the default when resolved
      expect(c.effectValuesFor('scanner')!.number('width'), 60);
      expect(c.fanQuantity, [1, 6, 3, 1]);
      expect(c.device(LightDeviceId.gpu).enabled, isTrue);
      final ch = c.device(LightDeviceId.chassis);
      expect(ch.mode, LightMode.canvas);
      expect(ch.enabled, isTrue);
      expect(ch.fixedColor, Rgb.white);
      expect(ch.placement.w, greaterThanOrEqualTo(1));
      expect(c.boardZones[0x22]!.mode, BoardEffectMode.static);
      expect(c.boardZones[0x22]!.speed, 9);
      expect(decodeLightingConfig(const {}), LightingConfig());
    });
  });

  group('composeFrame', () {
    test('LED count; hardware and GPU excluded from the map', () {
      final c = LightingConfig(fanQuantity: const [0, 3, 2, 0]).withDevice(
        LightDeviceId.motherboard,
        LightingConfig()
            .device(LightDeviceId.motherboard)
            .copyWith(mode: LightMode.hardware),
      );
      final f = composeFrame(c, 0);
      expect(f[LightDeviceId.alv2Group1]!.length, 60);
      expect(f[LightDeviceId.alv2Group2]!.length, 40);
      expect(f.containsKey(LightDeviceId.alv2Group3), isFalse);
      expect(f[LightDeviceId.chassis]!.length, 47);
      expect(f[LightDeviceId.ram1]!.length, 12);
      expect(f.containsKey(LightDeviceId.motherboard), isFalse);
      expect(f.containsKey(LightDeviceId.gpu), isFalse);
    });

    test('disabled and argbOff produce black', () {
      final base = LightingConfig(effectId: 'solid');
      final off = composeFrame(
        base.withDevice(
          LightDeviceId.chassis,
          base.device(LightDeviceId.chassis).copyWith(enabled: false),
        ),
        0,
      );
      expect(off[LightDeviceId.chassis]!.every((c) => c == Rgb.black), isTrue);
      expect(off[LightDeviceId.ram1]!.every((c) => c != Rgb.black), isTrue);
      final all = composeFrame(base.copyWith(argbOff: true), 0);
      expect(all.values.every((l) => l.every((c) => c == Rgb.black)), isTrue);
      expect(all[LightDeviceId.chassis]!.length, 47);
    });

    test('fixed color and 50% brightness', () {
      final base = LightingConfig(brightness: 0.5);
      final c = base.withDevice(
        LightDeviceId.ram1,
        base
            .device(LightDeviceId.ram1)
            .copyWith(
              mode: LightMode.fixed,
              fixedColor: const Rgb(200, 100, 50),
            ),
      );
      final f = composeFrame(c, 3);
      expect(
        f[LightDeviceId.ram1]!.every((x) => x == const Rgb(100, 50, 25)),
        isTrue,
      );
    });

    test('canvas follows the effect at the device position', () {
      final c = LightingConfig(effectId: 'solid')
          .withEffectValue('solid', 'color', '#0A141E');
      final f = composeFrame(c, 0);
      expect(f[LightDeviceId.chassis]!.first, const Rgb(10, 20, 30));
      // Sweep: the case (index 0 on the right) receives different values across the strip.
      final s = composeFrame(
        LightingConfig(effectId: 'rainbowWave'),
        1,
      )[LightDeviceId.chassis]!;
      expect(s.toSet().length, greaterThan(10));
    });

    test('unknown effect produces black', () {
      final f = composeFrame(LightingConfig(effectId: 'html:abc'), 0);
      expect(f[LightDeviceId.chassis]!.every((c) => c == Rgb.black), isTrue);
    });
  });
}
