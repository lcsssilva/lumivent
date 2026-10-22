import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/lighting/domain/frame_composer.dart';
import 'package:lumivent/features/lighting/domain/hardware_equivalents.dart';
import 'package:lumivent/features/lighting/domain/light_device.dart';
import 'package:lumivent/features/lighting/domain/lighting_config.dart';
import 'package:lumivent/features/lighting/infrastructure/lighting_codec.dart';
import 'package:lumivent/features/lighting/domain/rgb.dart';

LightingConfig cfg(
  String effect, [
  Map<String, Object?> values = const {},
  double brightness = 1,
]) => LightingConfig(
  effectId: effect,
  brightness: brightness,
  effectValues: {effect: values},
);

void main() {
  test('solid maps to static color with the effect color', () {
    final eq = hardwareEquivalentOf(cfg('solid', {'color': '#102030'}))!;
    expect(eq.fans.mode, 'StaticColor');
    expect(eq.fans.colors, List.filled(6, const Rgb(16, 32, 48)));
    expect(eq.board!.mode, BoardEffectMode.static);
    expect(eq.board!.color, const Rgb(16, 32, 48));
  });

  test('spectrum maps to rainbow morph / color cycle', () {
    final eq = hardwareEquivalentOf(cfg('spectrum'))!;
    expect(eq.fans.mode, 'RainbowMorph');
    expect(eq.board!.mode, BoardEffectMode.colorCycle);
  });

  test('breathing maps to breathing with the color; the board stays in '
      'Canvas', () {
    for (final speed in [1, 50, 100]) {
      final eq = hardwareEquivalentOf(
        cfg('breathing', {'color': '#FF0000', 'speed': speed}),
      )!;
      expect(eq.fans.mode, 'Breathing');
      expect(eq.fans.colors, List.filled(6, const Rgb(255, 0, 0)));
      // No ITE mode breathes with the fans: the zones follow the app clock.
      expect(eq.board, isNull);
    }
  });

  test('scanner maps to Scan with color + background, fans only', () {
    final eq = hardwareEquivalentOf(
      cfg('scanner', {'color': '#FF0000', 'background': '#000010'}),
    )!;
    expect(eq.fans.mode, 'Scan');
    expect(eq.fans.speed, 0);
    expect(eq.fans.colors.take(2), const [Rgb(255, 0, 0), Rgb(0, 0, 16)]);
    expect(eq.board, isNull);
  });

  test('color wave maps to Taichi with the two colors, speed and direction, '
      'fans only', () {
    final eq = hardwareEquivalentOf(
      cfg('colorWave', {
        'color': '#FF0080',
        'color2': '#0080FF',
        'speed': 100,
        'direction': 'Esquerda',
      }),
    )!;
    expect(eq.fans.mode, 'Taichi');
    expect(eq.fans.colors.take(2), const [Rgb(255, 0, 128), Rgb(0, 128, 255)]);
    // Taichi has speed in the firmware: the slider drives it.
    expect(eq.fans.speed, 4);
    expect(eq.fans.directionLeft, isTrue);
    expect(eq.board, isNull);
    expect(
      hardwareEquivalentOf(cfg('colorWave', {'direction': 'Direita'}))!
          .fans
          .directionLeft,
      isFalse,
    );
  });

  test('scanner/color wave keep the board in Canvas', () {
    for (final id in ['scanner', 'colorWave']) {
      final derived = withAutoHardware(cfg(id));
      for (final fan in [LightDeviceId.alv2Group1, LightDeviceId.alv2Group2]) {
        expect(derived.device(fan).mode, LightMode.hardware, reason: id);
      }
      expect(
        derived.device(LightDeviceId.motherboard).mode,
        LightMode.canvas,
        reason: id,
      );
    }
  });

  test('rainbow wave maps to rainbow / wave and the direction', () {
    expect(
      hardwareEquivalentOf(cfg('rainbowWave', {'direction': 'Esquerda'}))!
          .fans
          .directionLeft,
      isTrue,
    );
    final eq = hardwareEquivalentOf(cfg('rainbowWave', {'direction': 'Cima'}))!;
    expect(eq.fans.mode, 'Rainbow');
    expect(eq.fans.directionLeft, isFalse);
    expect(eq.board!.mode, BoardEffectMode.wave);
  });

  test('effects without an equivalent return null', () {
    for (final id in ['html:foo', 'nada']) {
      expect(hardwareEquivalentOf(cfg(id)), isNull, reason: id);
    }
  });

  test('speed range maps linearly to 0-4 (fans) and 0-9 (board)', () {
    HardwareEquivalent at(num speed) =>
        hardwareEquivalentOf(cfg('spectrum', {'speed': speed}))!;
    expect((at(1).fans.speed, at(1).board!.speed), (0, 0));
    expect((at(100).fans.speed, at(100).board!.speed), (4, 9));
    expect((at(50.5).fans.speed, at(50.5).board!.speed), (2, 5));
  });

  test('brightness maps to levels, 0 only when brightness is 0', () {
    HardwareEquivalent at(double b) =>
        hardwareEquivalentOf(cfg('spectrum', const {}, b))!;
    expect((at(1).fans.brightness, at(1).board!.brightness), (4, 9));
    expect((at(0.5).fans.brightness, at(0.5).board!.brightness), (2, 5));
    expect((at(0.01).fans.brightness, at(0.01).board!.brightness), (1, 1));
    expect((at(0).fans.brightness, at(0).board!.brightness), (0, 0));
  });

  test('autoHardware defaults to true and survives JSON', () {
    expect(LightingConfig().autoHardware, isTrue);
    expect(decodeLightingConfig(const {}).autoHardware, isTrue);
    expect(
      decodeLightingConfig(const {'autoHardware': 'x'}).autoHardware,
      isTrue,
    );
    final off = LightingConfig(autoHardware: false);
    expect(
      decodeLightingConfig(encodeLightingConfig(off)).autoHardware,
      isFalse,
    );
    expect(off == LightingConfig(), isFalse);
  });

  test('auto hardware devices: canvas devices the firmware took over', () {
    const html = 'html:demo';
    // No firmware equivalent: the fans stay in Canvas (slow streaming).
    expect(autoHardwareDevices(cfg(html)), isEmpty);
    expect(autoHardwareDevices(cfg('solid')), {
      LightDeviceId.alv2Group1,
      LightDeviceId.alv2Group2,
      LightDeviceId.alv2Group3,
      LightDeviceId.motherboard,
      LightDeviceId.gpu,
    });
    expect(
      autoHardwareDevices(cfg('solid').copyWith(autoHardware: false)),
      isEmpty,
    );
  });

  group('firmware speed', () {
    test('fixed for modes without speed, only with autoHardware', () {
      expect(firmwareSpeedFixed(cfg('scanner')), isTrue);
      // Taichi (color wave) has its own speed.
      expect(firmwareSpeedFixed(cfg('colorWave')), isFalse);
      expect(firmwareSpeedFixed(cfg('rainbowWave')), isFalse);
      expect(
        firmwareSpeedFixed(cfg('scanner').copyWith(autoHardware: false)),
        isFalse,
      );
    });

    test('the canvas ignores the speed slider for those effects', () {
      Rgb at(Map<String, Object?> values) => composeFrame(
        cfg('scanner', values),
        0.4,
      )[LightDeviceId.alv2Group1]!.first;
      expect(at({'speed': 1}), at({'speed': 100}));
      // Without the firmware mode the slider keeps working.
      final slow = cfg('scanner', {'speed': 1}).copyWith(autoHardware: false);
      final fast = cfg('scanner', {'speed': 100}).copyWith(autoHardware: false);
      expect(
        composeFrame(slow, 0.4)[LightDeviceId.alv2Group1]!.first,
        isNot(composeFrame(fast, 0.4)[LightDeviceId.alv2Group1]!.first),
      );
    });
  });
}
