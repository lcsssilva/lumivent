// Lighting module domain (pure Dart): lighting configuration.
//
// These are plain immutable value objects. The tolerant JSON codec (missing,
// unknown, or wrongly typed keys fall back per field, and the old
// `{"argbOff": true}` configuration remains valid) lives in
// `infrastructure/lighting_codec.dart`.

import 'package:freezed_annotation/freezed_annotation.dart';

import 'led_layout.dart';
import 'light_device.dart';
import 'native_effects.dart';
import 'rgb.dart';

part 'lighting_config.freezed.dart';

// Top-level constants are usable from the generated part; static members are
// not inherited by the generated implementation class.
const _alv2DefaultColors = [
  Rgb(255, 0, 0),
  Rgb(0, 0, 255),
  Rgb(0, 255, 0),
  Rgb(255, 255, 0),
  Rgb(255, 128, 0),
  Rgb(0, 255, 255),
];

const _gpuDefaultColors = [
  Rgb(255, 0, 0),
  Rgb(255, 128, 0),
  Rgb(255, 255, 0),
  Rgb(0, 255, 0),
  Rgb(0, 255, 255),
  Rgb(0, 0, 255),
  Rgb(160, 0, 255),
  Rgb(255, 255, 255),
];

const _defaultFanQuantity = [0, 3, 3, 1];
const _defaultMergeOrder = [0, 1, 2, 3];
const _defaultAlv2Hardware = <Alv2HardwareConfig>[
  Alv2HardwareConfig(),
  Alv2HardwareConfig(),
  Alv2HardwareConfig(),
  Alv2HardwareConfig(),
];
const _defaultBoardZones = <int, BoardZoneConfig>{
  0x20: BoardZoneConfig(),
  0x22: BoardZoneConfig(),
  0x23: BoardZoneConfig(),
};
const _defaultGpuHardware = GpuHardwareConfig();

// ── AL V2 fans (firmware hardware modes) ────────────────────────────

/// Firmware mode scope: whole fan or inner + outer rings.
enum Alv2Scope { whole, innerOuter }

/// Hardware mode for a hub group. The domain stores only the mode name
/// (`Rainbow`, `StaticColor_Inner`…); the byte table belongs to devices.
@freezed
abstract class Alv2HardwareConfig with _$Alv2HardwareConfig {
  const factory Alv2HardwareConfig({
    @Default(Alv2Scope.whole) Alv2Scope scope,
    @Default('StaticColor') String mode,

    /// Speed level, 0–4 (2 = normal).
    @Default(2) int speed,

    /// Brightness level, 0–4 (4 = 100%).
    @Default(4) int brightness,
    @Default(false) bool directionLeft,
    @Default(_alv2DefaultColors) List<Rgb> colors,
  }) = _Alv2HardwareConfig;

  /// Factory default (AL-V2 §4).
  static const defaultColors = _alv2DefaultColors;
}

extension Alv2HardwareColors on Alv2HardwareConfig {
  /// Color slot [index] of the mode; slots the config does not hold yet come
  /// from the factory defaults, cycling when the mode has more colors.
  Rgb colorAt(int index) => index < colors.length
      ? colors[index]
      : Alv2HardwareConfig.defaultColors[index %
            Alv2HardwareConfig.defaultColors.length];
}

// ── Motherboard (ITE hardware effects) ─────────────────────────────────────

/// Addressable motherboard zones: IO Shield 1, LED_CPU, and IO Shield 2
/// (ITE §1.2).
const boardZoneIds = [0x20, 0x22, 0x23];

enum BoardEffectMode { static, pulse, flash, doubleFlash, colorCycle, wave }

@freezed
abstract class BoardZoneConfig with _$BoardZoneConfig {
  const factory BoardZoneConfig({
    @Default(BoardEffectMode.static) BoardEffectMode mode,
    @Default(Rgb.white) Rgb color,

    /// 0–9.
    @Default(5) int speed,

    /// 0–9.
    @Default(9) int brightness,
  }) = _BoardZoneConfig;
}

// ── GPU (Gigabyte RX 9060 XT) ──────────────────────────────────────────────

/// Firmware effects of the GPU controller, in the order the UI shows them.
///
/// The byte codes belong to the devices module (`GpuEffectCode`); this enum
/// only carries the name the config persists. [colors] is the palette size
/// (only `ColorShift` uses one).
enum GpuEffect {
  off('Off'),
  staticColor('Static'),
  pulse('Pulse'),
  flash('Flash'),
  doubleFlash('DFlash'),
  cycle('Cycle'),
  wave('Wave'),
  gradient('Gradient'),
  colorShift('ColorShift', colors: 8),
  rainbow('Rainbow'),
  tricolor('Tricolor'),
  claws('Claws'),
  dazzle('Dazzle');

  const GpuEffect(this.styleName, {this.colors = 0});

  /// Effect name, as shown to the user.
  final String styleName;
  final int colors;

  /// Whether the firmware uses the speed byte for this effect.
  bool get hasSpeed => this != off && this != staticColor;

  /// Whether the firmware uses the brightness byte for this effect.
  bool get hasBrightness => this != off;
}

/// Hardware mode of the GPU: effect, speed/brightness (0–10) and colors.
@freezed
abstract class GpuHardwareConfig with _$GpuHardwareConfig {
  const factory GpuHardwareConfig({
    @Default(GpuEffect.pulse) GpuEffect effect,

    /// 0–10.
    @Default(5) int speed,

    /// 0–10.
    @Default(10) int brightness,

    /// Single color of effects without a palette.
    @Default(Rgb.white) Rgb color,
    @Default(_alv2DefaultColors) List<Rgb> colors,
  }) = _GpuHardwareConfig;

  /// Default palette for `ColorShift`; also the fallback for missing entries.
  static const defaultColors = _gpuDefaultColors;
}

// ── Devices ────────────────────────────────────────────────────────────

@freezed
abstract class DeviceLightConfig with _$DeviceLightConfig {
  const factory DeviceLightConfig({
    @Default(true) bool enabled,
    @Default(LightMode.canvas) LightMode mode,
    @Default(Rgb.white) Rgb fixedColor,
    required CanvasRect placement,
  }) = _DeviceLightConfig;

  /// Default for [id]: enabled in Canvas at the default position.
  factory DeviceLightConfig.defaults(LightDeviceId id) => DeviceLightConfig(
    enabled: id.isSupported,
    placement: CanvasRect.defaultFor(id),
  );
}

// ── General config ────────────────────────────────────────────────────────────

@Freezed(copyWith: false)
abstract class LightingConfig with _$LightingConfig {
  /// Generated constructor used by `copyWith`; the public factory below
  /// normalizes collections and fills per-device defaults.
  const factory LightingConfig.raw({
    @Default(false) bool argbOff,
    @Default(1) double brightness,
    @Default(true) bool offOnSleep,
    @Default(true) bool autoHardware,
    @Default(defaultEffectId) String effectId,
    @Default(<String, Map<String, Object?>>{})
    Map<String, Map<String, Object?>> effectValues,
    @Default(<LightDeviceId, DeviceLightConfig>{})
    Map<LightDeviceId, DeviceLightConfig> devices,
    @Default(_defaultFanQuantity) List<int> fanQuantity,
    @Default(_defaultAlv2Hardware) List<Alv2HardwareConfig> alv2Hardware,
    @Default(false) bool alv2Merge,
    @Default('Runway') String alv2MergeMode,
    @Default(_defaultMergeOrder) List<int> alv2MergeOrder,
    @Default(_defaultBoardZones) Map<int, BoardZoneConfig> boardZones,
    @Default(_defaultGpuHardware) GpuHardwareConfig gpuHardware,
  }) = _LightingConfig;

  factory LightingConfig({
    bool argbOff = false,
    double brightness = 1,
    bool offOnSleep = true,
    bool autoHardware = true,
    String effectId = defaultEffectId,
    Map<String, Map<String, Object?>> effectValues = const {},
    Map<LightDeviceId, DeviceLightConfig> devices = const {},
    List<int> fanQuantity = defaultFanQuantity,
    List<Alv2HardwareConfig>? alv2Hardware,
    bool alv2Merge = false,
    String alv2MergeMode = 'Runway',
    List<int> alv2MergeOrder = defaultMergeOrder,
    Map<int, BoardZoneConfig> boardZones = const {},
    GpuHardwareConfig gpuHardware = const GpuHardwareConfig(),
  }) {
    assert(fanQuantity.length == fanGroupSlots);
    assert(isMergeOrder(alv2MergeOrder));
    assert(alv2Hardware == null || alv2Hardware.length == fanGroupSlots);
    return LightingConfig.raw(
      argbOff: argbOff,
      brightness: brightness,
      offOnSleep: offOnSleep,
      autoHardware: autoHardware,
      effectId: effectId,
      effectValues: Map.unmodifiable({
        for (final entry in effectValues.entries)
          entry.key: Map<String, Object?>.unmodifiable(entry.value),
      }),
      devices: Map.unmodifiable({
        for (final id in LightDeviceId.values)
          id: devices[id] ?? DeviceLightConfig.defaults(id),
      }),
      fanQuantity: List.unmodifiable(fanQuantity),
      alv2Hardware: List.unmodifiable(alv2Hardware ?? _defaultAlv2Hardware),
      alv2Merge: alv2Merge,
      alv2MergeMode: alv2MergeMode,
      alv2MergeOrder: List.unmodifiable(alv2MergeOrder),
      boardZones: Map.unmodifiable({
        for (final zone in boardZoneIds)
          zone: boardZones[zone] ?? const BoardZoneConfig(),
      }),
      gpuHardware: gpuHardware,
    );
  }

  /// Hub groups (0–3).
  static const fanGroupSlots = 4;

  /// This machine since 2026-10-20: bottom 3 (G1), top 3 (G2), rear 1 (G3).
  static const defaultFanQuantity = _defaultFanQuantity;

  /// Hub default: the merge crosses the groups as numbered.
  static const defaultMergeOrder = _defaultMergeOrder;

  /// Whether [order] is a valid merge order: the 4 groups, each once, with
  /// the empty group 0 first (the app only reorders groups 1–3).
  static bool isMergeOrder(List<Object?> order) =>
      order.length == fanGroupSlots &&
      order.first == 0 &&
      {...order}.length == fanGroupSlots &&
      order.every((g) => g is int && g >= 0 && g < fanGroupSlots);
}

extension LightingConfigX on LightingConfig {
  /// Copies the config and re-applies the constructor normalization (complete
  /// device/zone maps and unmodifiable collections), like the former manual
  /// `copyWith` did.
  LightingConfig copyWith({
    bool? argbOff,
    double? brightness,
    bool? offOnSleep,
    bool? autoHardware,
    String? effectId,
    Map<String, Map<String, Object?>>? effectValues,
    Map<LightDeviceId, DeviceLightConfig>? devices,
    List<int>? fanQuantity,
    List<Alv2HardwareConfig>? alv2Hardware,
    bool? alv2Merge,
    String? alv2MergeMode,
    List<int>? alv2MergeOrder,
    Map<int, BoardZoneConfig>? boardZones,
    GpuHardwareConfig? gpuHardware,
  }) => LightingConfig(
    argbOff: argbOff ?? this.argbOff,
    brightness: brightness ?? this.brightness,
    offOnSleep: offOnSleep ?? this.offOnSleep,
    autoHardware: autoHardware ?? this.autoHardware,
    effectId: effectId ?? this.effectId,
    effectValues: effectValues ?? this.effectValues,
    devices: devices ?? this.devices,
    fanQuantity: fanQuantity ?? this.fanQuantity,
    alv2Hardware: alv2Hardware ?? this.alv2Hardware,
    alv2Merge: alv2Merge ?? this.alv2Merge,
    alv2MergeMode: alv2MergeMode ?? this.alv2MergeMode,
    alv2MergeOrder: alv2MergeOrder ?? this.alv2MergeOrder,
    boardZones: boardZones ?? this.boardZones,
    gpuHardware: gpuHardware ?? this.gpuHardware,
  );

  DeviceLightConfig device(LightDeviceId id) =>
      devices[id] ?? DeviceLightConfig.defaults(id);

  /// Fans of the group of [id] (0 outside fans).
  int fansOf(LightDeviceId id) => id.isFan ? fanQuantity[id.hubGroup!] : 0;

  /// Validated values of effect [id] (or of the current effect).
  EffectValues? effectValuesFor([String? id]) {
    final e = nativeEffectById(id ?? effectId);
    return e?.valuesFrom(effectValues[e.id] ?? const {});
  }

  LightingConfig withDevice(LightDeviceId id, DeviceLightConfig cfg) =>
      copyWith(devices: {...devices, id: cfg});

  LightingConfig withEffectValue(String effect, String key, Object value) =>
      copyWith(
        effectValues: {
          ...effectValues,
          effect: {...?effectValues[effect], key: value},
        },
      );
}

/// Persistence port for lighting configuration.
abstract interface class LightingConfigRepository {
  LightingConfig load();
  Future<void> save(LightingConfig config);
}
