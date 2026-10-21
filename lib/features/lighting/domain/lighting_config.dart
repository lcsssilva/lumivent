// Lighting module domain (pure Dart): lighting configuration.
//
// Reading tolerates missing, unknown or wrongly typed keys: each
// invalid fields use defaults. The old `{"argbOff": true}` configuration remains
// valid.

import 'led_layout.dart';
import 'light_device.dart';
import 'native_effects.dart';
import 'rgb.dart';

// ── AL V2 fans (firmware hardware modes) ────────────────────────────

/// Firmware mode scope: whole fan or inner + outer rings.
enum Alv2Scope { whole, innerOuter }

/// Hardware mode for a hub group. The domain stores only the mode name
/// (`Rainbow`, `StaticColor_Inner`…); the byte table belongs to devices.
class Alv2HardwareConfig {
  const Alv2HardwareConfig({
    this.scope = Alv2Scope.whole,
    this.mode = 'StaticColor',
    this.speed = 2,
    this.brightness = 4,
    this.directionLeft = false,
    this.colors = defaultColors,
  });

  /// Factory default (AL-V2 §4).
  static const defaultColors = [
    Rgb(255, 0, 0),
    Rgb(0, 0, 255),
    Rgb(0, 255, 0),
    Rgb(255, 255, 0),
    Rgb(255, 128, 0),
    Rgb(0, 255, 255),
  ];

  final Alv2Scope scope;
  final String mode;

  /// Speed level, 0–4 (2 = normal).
  final int speed;

  /// Brightness level, 0–4 (4 = 100%).
  final int brightness;
  final bool directionLeft;
  final List<Rgb> colors;

  Alv2HardwareConfig copyWith({
    Alv2Scope? scope,
    String? mode,
    int? speed,
    int? brightness,
    bool? directionLeft,
    List<Rgb>? colors,
  }) => Alv2HardwareConfig(
    scope: scope ?? this.scope,
    mode: mode ?? this.mode,
    speed: speed ?? this.speed,
    brightness: brightness ?? this.brightness,
    directionLeft: directionLeft ?? this.directionLeft,
    colors: colors ?? this.colors,
  );

  factory Alv2HardwareConfig.fromJson(Object? json) {
    const d = Alv2HardwareConfig();
    if (json is! Map) return d;
    final mode = json['mode'];
    final colors = json['colors'];
    return Alv2HardwareConfig(
      scope:
          Alv2Scope.values.where((s) => s.name == json['scope']).firstOrNull ??
          d.scope,
      mode: mode is String && mode.isNotEmpty ? mode : d.mode,
      speed: _level(json['speed'], 4, d.speed),
      brightness: _level(json['brightness'], 4, d.brightness),
      directionLeft: json['directionLeft'] is bool
          ? json['directionLeft'] as bool
          : d.directionLeft,
      colors: colors is List
          ? List.unmodifiable([
              for (final c in colors) ?(c is String ? Rgb.parse(c) : null),
            ])
          : d.colors,
    );
  }

  Map<String, Object?> toJson() => {
    'scope': scope.name,
    'mode': mode,
    'speed': speed,
    'brightness': brightness,
    'directionLeft': directionLeft,
    'colors': [for (final c in colors) c.toHex()],
  };

  @override
  bool operator ==(Object other) =>
      other is Alv2HardwareConfig &&
      other.scope == scope &&
      other.mode == mode &&
      other.speed == speed &&
      other.brightness == brightness &&
      other.directionLeft == directionLeft &&
      _listEq(other.colors, colors);

  @override
  int get hashCode => Object.hash(
    scope,
    mode,
    speed,
    brightness,
    directionLeft,
    Object.hashAll(colors),
  );
}

// ── Motherboard (ITE hardware effects) ─────────────────────────────────────

/// Addressable motherboard zones: IO Shield 1, LED_CPU, and IO Shield 2
/// (ITE §1.2).
const boardZoneIds = [0x20, 0x22, 0x23];

enum BoardEffectMode { static, pulse, flash, doubleFlash, colorCycle, wave }

class BoardZoneConfig {
  const BoardZoneConfig({
    this.mode = BoardEffectMode.static,
    this.color = Rgb.white,
    this.speed = 5,
    this.brightness = 9,
  });

  final BoardEffectMode mode;
  final Rgb color;

  /// 0–9.
  final int speed;

  /// 0–9.
  final int brightness;

  BoardZoneConfig copyWith({
    BoardEffectMode? mode,
    Rgb? color,
    int? speed,
    int? brightness,
  }) => BoardZoneConfig(
    mode: mode ?? this.mode,
    color: color ?? this.color,
    speed: speed ?? this.speed,
    brightness: brightness ?? this.brightness,
  );

  factory BoardZoneConfig.fromJson(Object? json) {
    const d = BoardZoneConfig();
    if (json is! Map) return d;
    return BoardZoneConfig(
      mode:
          BoardEffectMode.values
              .where((m) => m.name == json['mode'])
              .firstOrNull ??
          d.mode,
      color:
          (json['color'] is String
              ? Rgb.parse(json['color'] as String)
              : null) ??
          d.color,
      speed: _level(json['speed'], 9, d.speed),
      brightness: _level(json['brightness'], 9, d.brightness),
    );
  }

  Map<String, Object?> toJson() => {
    'mode': mode.name,
    'color': color.toHex(),
    'speed': speed,
    'brightness': brightness,
  };

  @override
  bool operator ==(Object other) =>
      other is BoardZoneConfig &&
      other.mode == mode &&
      other.color == color &&
      other.speed == speed &&
      other.brightness == brightness;

  @override
  int get hashCode => Object.hash(mode, color, speed, brightness);
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
class GpuHardwareConfig {
  const GpuHardwareConfig({
    this.effect = GpuEffect.pulse,
    this.speed = 5,
    this.brightness = 10,
    this.color = Rgb.white,
    this.colors = defaultColors,
  });

  /// Default palette for `ColorShift`; also the fallback for missing entries.
  static const defaultColors = [
    Rgb(255, 0, 0),
    Rgb(255, 128, 0),
    Rgb(255, 255, 0),
    Rgb(0, 255, 0),
    Rgb(0, 255, 255),
    Rgb(0, 0, 255),
    Rgb(160, 0, 255),
    Rgb(255, 255, 255),
  ];

  final GpuEffect effect;

  /// 0–10.
  final int speed;

  /// 0–10.
  final int brightness;

  /// Single color of effects without a palette.
  final Rgb color;
  final List<Rgb> colors;

  GpuHardwareConfig copyWith({
    GpuEffect? effect,
    int? speed,
    int? brightness,
    Rgb? color,
    List<Rgb>? colors,
  }) => GpuHardwareConfig(
    effect: effect ?? this.effect,
    speed: speed ?? this.speed,
    brightness: brightness ?? this.brightness,
    color: color ?? this.color,
    colors: colors ?? this.colors,
  );

  factory GpuHardwareConfig.fromJson(Object? json) {
    const d = GpuHardwareConfig();
    if (json is! Map) return d;
    final rawColors = json['colors'];
    return GpuHardwareConfig(
      effect:
          GpuEffect.values.where((e) => e.name == json['effect']).firstOrNull ??
          d.effect,
      speed: _level(json['speed'], 10, d.speed),
      brightness: _level(json['brightness'], 10, d.brightness),
      color:
          (json['color'] is String
              ? Rgb.parse(json['color'] as String)
              : null) ??
          d.color,
      colors: rawColors is List && rawColors.isNotEmpty
          ? List.unmodifiable([
              for (final c in rawColors) ?(c is String ? Rgb.parse(c) : null),
            ])
          : d.colors,
    );
  }

  Map<String, Object?> toJson() => {
    'effect': effect.name,
    'speed': speed,
    'brightness': brightness,
    'color': color.toHex(),
    'colors': [for (final c in colors) c.toHex()],
  };

  @override
  bool operator ==(Object other) =>
      other is GpuHardwareConfig &&
      other.effect == effect &&
      other.speed == speed &&
      other.brightness == brightness &&
      other.color == color &&
      _listEq(other.colors, colors);

  @override
  int get hashCode =>
      Object.hash(effect, speed, brightness, color, Object.hashAll(colors));
}

// ── Devices ────────────────────────────────────────────────────────────

class DeviceLightConfig {
  const DeviceLightConfig({
    this.enabled = true,
    this.mode = LightMode.canvas,
    this.fixedColor = Rgb.white,
    required this.placement,
  });

  /// Default for [id]: enabled in Canvas at the default position.
  factory DeviceLightConfig.defaults(LightDeviceId id) => DeviceLightConfig(
    enabled: id.isSupported,
    placement: CanvasRect.defaultFor(id),
  );

  final bool enabled;
  final LightMode mode;
  final Rgb fixedColor;
  final CanvasRect placement;

  DeviceLightConfig copyWith({
    bool? enabled,
    LightMode? mode,
    Rgb? fixedColor,
    CanvasRect? placement,
  }) => DeviceLightConfig(
    enabled: enabled ?? this.enabled,
    mode: mode ?? this.mode,
    fixedColor: fixedColor ?? this.fixedColor,
    placement: placement ?? this.placement,
  );

  factory DeviceLightConfig.fromJson(LightDeviceId id, Object? json) {
    final d = DeviceLightConfig.defaults(id);
    if (json is! Map || !id.isSupported) return d;
    final mode = LightMode.values
        .where((m) => m.name == json['mode'])
        .firstOrNull;
    return DeviceLightConfig(
      enabled: json['enabled'] is bool ? json['enabled'] as bool : d.enabled,
      mode: mode != null && id.accepts(mode) ? mode : d.mode,
      fixedColor:
          (json['fixedColor'] is String
              ? Rgb.parse(json['fixedColor'] as String)
              : null) ??
          d.fixedColor,
      placement: CanvasRect.fromJson(json['placement'], d.placement),
    );
  }

  Map<String, Object?> toJson() => {
    'enabled': enabled,
    'mode': mode.name,
    'fixedColor': fixedColor.toHex(),
    'placement': placement.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is DeviceLightConfig &&
      other.enabled == enabled &&
      other.mode == mode &&
      other.fixedColor == fixedColor &&
      other.placement == placement;

  @override
  int get hashCode => Object.hash(enabled, mode, fixedColor, placement);
}

// ── General config ────────────────────────────────────────────────────────────

class LightingConfig {
  LightingConfig({
    this.argbOff = false,
    this.brightness = 1,
    this.offOnSleep = true,
    this.autoHardware = true,
    this.effectId = defaultEffectId,
    Map<String, Map<String, Object?>> effectValues = const {},
    Map<LightDeviceId, DeviceLightConfig> devices = const {},
    List<int> fanQuantity = defaultFanQuantity,
    List<Alv2HardwareConfig>? alv2Hardware,
    this.alv2Merge = false,
    this.alv2MergeMode = 'Runway',
    List<int> alv2MergeOrder = defaultMergeOrder,
    Map<int, BoardZoneConfig> boardZones = const {},
    this.gpuHardware = const GpuHardwareConfig(),
  }) : effectValues = Map<String, Map<String, Object?>>.unmodifiable({
         for (final e in effectValues.entries)
           e.key: Map<String, Object?>.unmodifiable(e.value),
       }),
       devices = Map.unmodifiable({
         for (final id in LightDeviceId.values)
           id: devices[id] ?? DeviceLightConfig.defaults(id),
       }),
       fanQuantity = List.unmodifiable(fanQuantity),
       alv2MergeOrder = List.unmodifiable(alv2MergeOrder),
       alv2Hardware = List.unmodifiable(
         alv2Hardware ?? List.filled(fanGroupSlots, const Alv2HardwareConfig()),
       ),
       boardZones = Map.unmodifiable({
         for (final z in boardZoneIds)
           z: boardZones[z] ?? const BoardZoneConfig(),
       }),
       assert(fanQuantity.length == fanGroupSlots),
       assert(isMergeOrder(alv2MergeOrder)),
       assert(alv2Hardware == null || alv2Hardware.length == fanGroupSlots);

  /// Hub groups (0–3).
  static const fanGroupSlots = 4;

  /// This machine since 2026-10-20: bottom 3 (G1), top 3 (G2), rear 1 (G3).
  static const defaultFanQuantity = [0, 3, 3, 1];

  /// Hub default: the merge crosses the groups as numbered.
  static const defaultMergeOrder = [0, 1, 2, 3];

  /// Whether [order] is a valid merge order: the 4 groups, each once, with
  /// the empty group 0 first (the app only reorders groups 1–3).
  static bool isMergeOrder(List<Object?> order) =>
      order.length == fanGroupSlots &&
      order.first == 0 &&
      {...order}.length == fanGroupSlots &&
      order.every((g) => g is int && g >= 0 && g < fanGroupSlots);

  /// Turn off all ARGB (UI label "Desligar todos os ARGB").
  final bool argbOff;

  /// Global brightness, 0–1.
  final double brightness;

  /// Turn off on suspend/shutdown.
  final bool offOnSleep;

  /// Use the firmware's own modes (fans, motherboard) instead of streaming
  /// frames when the global effect has a hardware equivalent.
  final bool autoHardware;

  /// Global effect (native id or, in phase 5, of an HTML effect).
  final String effectId;

  /// Parameter values by effect ID.
  final Map<String, Map<String, Object?>> effectValues;
  final Map<LightDeviceId, DeviceLightConfig> devices;

  /// Fans per hub group (indexes 0–3), 0–6 each.
  final List<int> fanQuantity;

  /// Hardware mode per hub group (indexes 0–3). Index 0 has no fans, so it
  /// holds the merge settings (colors, speed, brightness, direction).
  final List<Alv2HardwareConfig> alv2Hardware;

  /// Global merge between groups (replaces the per-group modes).
  final bool alv2Merge;
  final String alv2MergeMode;

  /// Groups in the order the merge crosses them (`MergeOrder` in the protocol notes:
  /// item i is the group at position i), so it can follow the physical path
  /// whatever port each chain is plugged into.
  final List<int> alv2MergeOrder;

  /// Per zone (`0x20`, `0x22`, `0x23`).
  final Map<int, BoardZoneConfig> boardZones;

  /// Hardware mode of the GPU (`LightMode.hardware`).
  final GpuHardwareConfig gpuHardware;

  DeviceLightConfig device(LightDeviceId id) => devices[id]!;

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

  factory LightingConfig.fromJson(Map<String, Object?> json) {
    final b = json['brightness'];
    final eid = json['effectId'];

    final ev = <String, Map<String, Object?>>{};
    final rawEv = json['effectValues'];
    if (rawEv is Map) {
      for (final e in rawEv.entries) {
        final v = e.value;
        if (e.key is! String || v is! Map) continue;
        ev[e.key as String] = {
          for (final p in v.entries)
            if (p.key is String &&
                (p.value is num || p.value is bool || p.value is String))
              p.key as String: p.value,
        };
      }
    }

    final rawDev = json['devices'];
    final devices = {
      for (final id in LightDeviceId.values)
        id: DeviceLightConfig.fromJson(
          id,
          rawDev is Map ? rawDev[id.name] : null,
        ),
    };

    final fq = json['fanQuantity'];
    final fanQty = [
      for (var i = 0; i < fanGroupSlots; i++)
        fq is List && i < fq.length && fq[i] is int
            ? (fq[i] as int).clamp(0, maxFansPerGroup)
            : defaultFanQuantity[i],
    ];

    final hw = json['alv2Hardware'];
    final alv2 = [
      for (var i = 0; i < fanGroupSlots; i++)
        Alv2HardwareConfig.fromJson(hw is List && i < hw.length ? hw[i] : null),
    ];

    final mm = json['alv2MergeMode'];
    final mo = json['alv2MergeOrder'];
    final rawZones = json['boardZones'];
    final zones = {
      for (final z in boardZoneIds)
        z: BoardZoneConfig.fromJson(
          rawZones is Map ? rawZones[_zoneKey(z)] : null,
        ),
    };

    return LightingConfig(
      argbOff: json['argbOff'] is bool ? json['argbOff'] as bool : false,
      brightness: b is num && b.isFinite ? b.toDouble().clamp(0.0, 1.0) : 1,
      offOnSleep: json['offOnSleep'] is bool
          ? json['offOnSleep'] as bool
          : true,
      autoHardware: json['autoHardware'] is bool
          ? json['autoHardware'] as bool
          : true,
      effectId: eid is String && eid.isNotEmpty ? eid : defaultEffectId,
      effectValues: ev,
      devices: devices,
      fanQuantity: fanQty,
      alv2Hardware: alv2,
      alv2Merge: json['alv2Merge'] is bool ? json['alv2Merge'] as bool : false,
      alv2MergeMode: mm is String && mm.isNotEmpty ? mm : 'Runway',
      alv2MergeOrder: mo is List && isMergeOrder(mo)
          ? mo.cast<int>()
          : defaultMergeOrder,
      boardZones: zones,
      gpuHardware: GpuHardwareConfig.fromJson(json['gpuHardware']),
    );
  }

  Map<String, Object?> toJson() => {
    'argbOff': argbOff,
    'brightness': brightness,
    'offOnSleep': offOnSleep,
    'autoHardware': autoHardware,
    'effectId': effectId,
    'effectValues': effectValues,
    'devices': {for (final e in devices.entries) e.key.name: e.value.toJson()},
    'fanQuantity': fanQuantity,
    'alv2Hardware': [for (final h in alv2Hardware) h.toJson()],
    'alv2Merge': alv2Merge,
    'alv2MergeMode': alv2MergeMode,
    'alv2MergeOrder': alv2MergeOrder,
    'boardZones': {
      for (final e in boardZones.entries) _zoneKey(e.key): e.value.toJson(),
    },
    'gpuHardware': gpuHardware.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is LightingConfig &&
      other.argbOff == argbOff &&
      other.brightness == brightness &&
      other.offOnSleep == offOnSleep &&
      other.autoHardware == autoHardware &&
      other.effectId == effectId &&
      _mapEq(
        other.effectValues,
        effectValues,
        (a, b) => _mapEq(a, b, (x, y) => x == y),
      ) &&
      _mapEq(other.devices, devices, (a, b) => a == b) &&
      _listEq(other.fanQuantity, fanQuantity) &&
      _listEq(other.alv2Hardware, alv2Hardware) &&
      other.alv2Merge == alv2Merge &&
      other.alv2MergeMode == alv2MergeMode &&
      _listEq(other.alv2MergeOrder, alv2MergeOrder) &&
      _mapEq(other.boardZones, boardZones, (a, b) => a == b) &&
      other.gpuHardware == gpuHardware;

  @override
  int get hashCode => Object.hashAll([
    argbOff,
    brightness,
    offOnSleep,
    autoHardware,
    effectId,
    Object.hashAll(
      effectValues.entries.map(
        (e) => Object.hash(
          e.key,
          Object.hashAll(
            e.value.entries.map((p) => Object.hash(p.key, p.value)),
          ),
        ),
      ),
    ),
    Object.hashAll(devices.values),
    Object.hashAll(fanQuantity),
    Object.hashAll(alv2Hardware),
    alv2Merge,
    alv2MergeMode,
    Object.hashAll(alv2MergeOrder),
    Object.hashAll(boardZones.values),
    gpuHardware,
  ]);
}

String _zoneKey(int zone) => '0x${zone.toRadixString(16).toUpperCase()}';

int _level(Object? v, int max, int fallback) =>
    v is int ? v.clamp(0, max) : fallback;

bool _listEq<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _mapEq<K, V>(Map<K, V> a, Map<K, V> b, bool Function(V, V) eq) {
  if (a.length != b.length) return false;
  for (final e in a.entries) {
    if (!b.containsKey(e.key) || !eq(e.value, b[e.key] as V)) return false;
  }
  return true;
}

/// Persistence port for lighting configuration.
abstract interface class LightingConfigRepository {
  LightingConfig load();
  Future<void> save(LightingConfig config);
}
