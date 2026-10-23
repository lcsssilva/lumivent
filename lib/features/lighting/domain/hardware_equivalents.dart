// Lighting module domain (pure Dart): firmware equivalents of native effects.
//
// The AL V2 hub streams at ~19 fps at best and shows frames ~150 ms late,
// while the firmware animates its own modes smoothly. When the global effect
// has a hardware counterpart, the engine can hand fans and motherboard zones
// to the firmware instead of streaming frames. The domain only knows mode
// names (firmware mode strings) and [BoardEffectMode]; the byte tables belong to
// the device drivers.

import 'package:freezed_annotation/freezed_annotation.dart';

import 'hardware_timing.dart';
import 'light_device.dart';
import 'lighting_config.dart';
import 'native_effects.dart';
import 'rgb.dart';

part 'hardware_equivalents.freezed.dart';

/// Firmware mode chosen for the **Varredura** effect.
///
/// `[OBS]` Picked on the hardware (2026-10-20, `hw_test_fase4.dart hwall`,
/// checklist 4.1 §3): Scan 5, Runway 4, MopUp 4 (MopUp leaves a G2 LED dark).
/// The top fans swept the opposite way (then G3), from how they are chained;
/// Scan ignores the direction byte, so only the wiring can fix it (re-wired
/// 2026-10-20: top is now G2, rear G3).
const scannerFirmwareMode = 'Scan';

/// Firmware mode chosen for the **Onda de duas cores** effect.
///
/// `[OBS]` Picked on the hardware (2026-10-20, checklist 4.1 §4): Mixing 4,
/// Taichi 4; Taichi wins because it has speed and direction in the firmware.
const colorWaveFirmwareMode = 'Taichi';

/// Firmware mode of the **Breathing** effect (`breathingEffectId`): the
/// canvas devices lock their phase to it.
const breathingFirmwareMode = 'Breathing';

/// Effects whose firmware mode has no speed control; the canvas runs at the
/// firmware's fixed pace instead ([firmwareFixedEffectSpeed]).
const fixedSpeedEffects = {'scanner'};

/// Hardware configuration equivalent to the current global effect.
@freezed
abstract class HardwareEquivalent with _$HardwareEquivalent {
  const factory HardwareEquivalent({
    /// For every fan group in Canvas.
    required Alv2HardwareConfig fans,

    /// For every motherboard zone, when the board is in Canvas; `null` when the
    /// firmware has no equivalent for the zones (they stay in Canvas).
    required BoardZoneConfig? board,

    /// For the GPU, when the firmware has a matching effect; `null` leaves it
    /// in Canvas (average color).
    GpuHardwareConfig? gpu,
  }) = _HardwareEquivalent;
}

/// Hardware equivalent of the effect in [c], or `null` when it has none
/// (HTML effects): those stay in Canvas.
///
/// * solid -> `StaticColor` / `static` / GPU `Static`
/// * spectrum -> `RainbowMorph` / `colorCycle` / GPU `Cycle`
/// * breathing -> `Breathing`, no board equivalent / GPU `Pulse`
/// * rainbowWave -> `Rainbow` (direction "Left" = left) / `wave` / GPU `Rainbow`
/// * scanner -> `Scan`, color + background, fans only, fixed speed
/// * colorWave -> `Taichi`, the two colors and the direction, fans only
///
/// Speed (the effect's `speed` range) maps linearly to 0-4 on fans, 0-9 on the
/// board and 0-10 on the GPU; global brightness (0-1) maps linearly to
/// 0-4 / 0-9 / 0-10, and is 0 only when the brightness is 0.
HardwareEquivalent? hardwareEquivalentOf(LightingConfig c) {
  final effect = nativeEffectById(c.effectId);
  final values = c.effectValuesFor();
  if (effect == null || values == null) return null;

  final speedParam = effect.params.where((p) => p.id == 'speed').firstOrNull;
  final speed = speedParam == null ? 0.5 : _fraction(speedParam, values);
  // Scanner uses a firmware mode without speed control: the canvas runs at
  // [firmwareFixedEffectSpeed] and the (ignored) speed field stays at 0, so
  // the packet does not follow the disabled slider.
  final fixed = fixedSpeedEffects.contains(effect.id);
  final fanSpeed = fixed ? 0 : (speed * 4).round();
  final boardSpeed = fixed ? 0 : (speed * 9).round();
  final fanBrightness = _level(c.brightness, 4);
  final boardBrightness = _level(c.brightness, 9);
  final gpuSpeed = fixed ? 0 : (speed * 10).round();
  final gpuBrightness = _level(c.brightness, 10);

  Alv2HardwareConfig fans(
    String mode, {
    Rgb? color,
    List<Rgb>? colors,
    bool left = false,
  }) => Alv2HardwareConfig(
    mode: mode,
    speed: fanSpeed,
    brightness: fanBrightness,
    directionLeft: left,
    // Modes that ask for N colors get the palette repeated; a mode with no
    // palette gets the single color (or white).
    colors: List.generate(6, (i) {
      if (colors == null || colors.isEmpty) return color ?? Rgb.white;
      return colors[i % colors.length];
    }),
  );

  BoardZoneConfig board(BoardEffectMode mode, {Rgb? color}) => BoardZoneConfig(
    mode: mode,
    color: color ?? Rgb.white,
    speed: boardSpeed,
    brightness: boardBrightness,
  );

  GpuHardwareConfig gpu(GpuEffect effect, {Rgb color = Rgb.white}) =>
      GpuHardwareConfig(
        effect: effect,
        // Static has no animation: the speed byte is unused.
        speed: effect == GpuEffect.staticColor ? 0 : gpuSpeed,
        brightness: gpuBrightness,
        color: color,
      );

  switch (effect.id) {
    case 'solid':
      final color = values.color('color');
      return HardwareEquivalent(
        fans: fans('StaticColor', color: color),
        board: board(BoardEffectMode.static, color: color),
        gpu: gpu(GpuEffect.staticColor, color: color),
      );
    case 'spectrum':
      return HardwareEquivalent(
        fans: fans('RainbowMorph'),
        board: board(BoardEffectMode.colorCycle),
        gpu: gpu(GpuEffect.cycle),
      );
    case breathingEffectId:
      // The board has no matching firmware mode: the ITE `Pulse` runs 1–3,4 s
      // (2 × wT0 + 200 ms, measured 2026-10-20) against 3,3–11,6 s on the
      // fans, and keeps running when resent while the fans restart. The zones
      // stay in Canvas and breathe on the app clock with the fans.
      return HardwareEquivalent(
        fans: fans(breathingFirmwareMode, color: values.color('color')),
        board: null,
        gpu: gpu(GpuEffect.pulse, color: values.color('color')),
      );
    case 'rainbowWave':
      return HardwareEquivalent(
        fans: fans('Rainbow', left: values.option('direction') == 'Left'),
        board: board(BoardEffectMode.wave),
        gpu: gpu(GpuEffect.rainbow),
      );
    case 'scanner':
      return HardwareEquivalent(
        fans: fans(
          scannerFirmwareMode,
          colors: [values.color('color'), values.color('background')],
        ),
        board: null,
      );
    case 'colorWave':
      return HardwareEquivalent(
        fans: fans(
          colorWaveFirmwareMode,
          colors: [values.color('color'), values.color('color2')],
          left: values.option('direction') == 'Left',
        ),
        board: null,
      );
    default:
      return null;
  }
}

/// The config the engine acts on for the user config [user].
///
/// With `autoHardware` and a firmware equivalent of the global effect
/// ([hardwareEquivalentOf]), every enabled fan group and the motherboard
/// that are in Canvas become hardware devices carrying the derived mode.
/// Devices the user put in Hardware or Fixed color are untouched, and the
/// case strip and RAM stay in Canvas (no useful firmware mode).
LightingConfig withAutoHardware(LightingConfig user) {
  if (!user.autoHardware) return user;
  final eq = hardwareEquivalentOf(user);
  if (eq == null) return user;
  var c = user;
  final fans = [...user.alv2Hardware];
  for (final id in LightDeviceId.values.where((d) => d.isFan)) {
    final d = user.device(id);
    if (!d.enabled || d.mode != LightMode.canvas) continue;
    c = c.withDevice(id, d.copyWith(mode: LightMode.hardware));
    fans[id.hubGroup!] = eq.fans;
  }
  final board = user.device(LightDeviceId.motherboard);
  var zones = user.boardZones;
  final boardEq = eq.board;
  if (boardEq != null && board.enabled && board.mode == LightMode.canvas) {
    c = c.withDevice(
      LightDeviceId.motherboard,
      board.copyWith(mode: LightMode.hardware),
    );
    zones = {for (final z in boardZoneIds) z: boardEq};
  }
  final gpu = user.device(LightDeviceId.gpu);
  final gpuEq = eq.gpu;
  var gpuHardware = user.gpuHardware;
  if (gpuEq != null && gpu.enabled && gpu.mode == LightMode.canvas) {
    c = c.withDevice(LightDeviceId.gpu, gpu.copyWith(mode: LightMode.hardware));
    gpuHardware = gpuEq;
  }
  return c.copyWith(
    alv2Hardware: fans,
    boardZones: zones,
    gpuHardware: gpuHardware,
  );
}

/// Whether the fans run a firmware mode without speed control for the current
/// effect, so the canvas speed is fixed ([firmwareFixedEffectSpeed]) instead
/// of following the slider. The effect panel warns the user.
bool firmwareSpeedFixed(LightingConfig user) =>
    user.autoHardware &&
    fixedSpeedEffects.contains(user.effectId) &&
    nativeEffectById(user.effectId) != null;

/// Minimum interval between AL V2 canvas frames. Fans of an effect without
/// firmware equivalent (HTML effects, or `autoHardware` off) stream the
/// canvas at this pace.
///
/// Measured on hardware (2026-10-20, `alv2_stream_bench.dart slow2/slow5`
/// `+probe10`, duty 60 %, the app's packet sequence): at 2 fps the RPM stays at
/// the no-streaming baseline (975/1200/1215) for 2 min and the fans sound
/// steady; at 5 fps it drops by up to 15 %. Faster streaming (8–19 fps,
/// AL-V2 §9.1) also makes the speed oscillate audibly.
const alv2SafeStreamGap = Duration(milliseconds: 500);

/// Ids of devices running a firmware mode derived by [withAutoHardware].
Set<LightDeviceId> autoHardwareDevices(LightingConfig user) {
  final eff = withAutoHardware(user);
  return {
    for (final id in LightDeviceId.values)
      if (user.device(id).mode == LightMode.canvas &&
          eff.device(id).mode == LightMode.hardware)
        id,
  };
}

/// Position of the `speed` value inside the parameter range, 0-1.
double _fraction(EffectParam p, EffectValues v) {
  final span = p.max! - p.min!;
  if (span <= 0) return 0.5;
  return ((v.number(p.id) - p.min!) / span).clamp(0.0, 1.0);
}

/// Brightness 0-1 as a level 0..[max]; 0 only for brightness 0.
int _level(double brightness, int max) {
  if (brightness <= 0) return 0;
  return (brightness * max).round().clamp(1, max);
}
