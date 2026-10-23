// JSON codec for the lighting section.
//
// Reading tolerates missing, unknown, or wrongly typed keys: invalid fields use
// their defaults. The old `{"argbOff": true}` configuration remains valid. The
// persisted shape does not depend on the freezed generated code.

import '../../../core/persistence/config_store.dart';
import '../domain/led_layout.dart';
import '../domain/canvas_rect.dart';
import '../domain/light_device.dart';
import '../domain/lighting_config.dart';
import '../domain/board_zone_config.dart';
import '../domain/device_light_config.dart';
import '../domain/native_effects.dart';
import '../domain/rgb.dart';

LightingConfig decodeLightingConfig(JsonMap json) {
  final brightness = json['brightness'];
  final effectId = json['effectId'];

  final effectValues = <String, Map<String, Object?>>{};
  final rawEffectValues = json['effectValues'];
  if (rawEffectValues is Map) {
    for (final entry in rawEffectValues.entries) {
      final value = entry.value;
      if (entry.key is! String || value is! Map) continue;
      effectValues[entry.key as String] = {
        for (final parameter in value.entries)
          if (parameter.key is String &&
              (parameter.value is num ||
                  parameter.value is bool ||
                  parameter.value is String))
            parameter.key as String: parameter.value,
      };
    }
  }

  final rawDevices = json['devices'];
  final devices = <LightDeviceId, DeviceLightConfig>{};
  for (final id in LightDeviceId.values) {
    final decoded = decodeDeviceLightConfig(
      id,
      rawDevices is Map ? rawDevices[id.name] : null,
    );
    // Keep the field sparse: missing devices mean their default. This keeps
    // `decodeLightingConfig({}) == LightingConfig()`.
    if (decoded != DeviceLightConfig.defaults(id)) devices[id] = decoded;
  }

  final rawFanQuantity = json['fanQuantity'];
  final fanQuantity = [
    for (var i = 0; i < LightingConfig.fanGroupSlots; i++)
      rawFanQuantity is List &&
              i < rawFanQuantity.length &&
              rawFanQuantity[i] is int
          ? (rawFanQuantity[i] as int).clamp(0, maxFansPerGroup)
          : LightingConfig.defaultFanQuantity[i],
  ];

  final rawHardware = json['alv2Hardware'];
  final alv2Hardware = [
    for (var i = 0; i < LightingConfig.fanGroupSlots; i++)
      decodeAlv2HardwareConfig(
        rawHardware is List && i < rawHardware.length ? rawHardware[i] : null,
      ),
  ];

  final mergeMode = json['alv2MergeMode'];
  final mergeOrder = json['alv2MergeOrder'];
  final rawZones = json['boardZones'];
  final boardZones = {
    for (final zone in boardZoneIds)
      zone: decodeBoardZoneConfig(
        rawZones is Map ? rawZones[_zoneKey(zone)] : null,
      ),
  };

  return LightingConfig(
    argbOff: json['argbOff'] is bool ? json['argbOff'] as bool : false,
    brightness: brightness is num && brightness.isFinite
        ? brightness.toDouble().clamp(0.0, 1.0)
        : 1,
    offOnSleep: json['offOnSleep'] is bool ? json['offOnSleep'] as bool : true,
    autoHardware: json['autoHardware'] is bool
        ? json['autoHardware'] as bool
        : true,
    effectId: effectId is String && effectId.isNotEmpty
        ? effectId
        : defaultEffectId,
    effectValues: effectValues,
    devices: devices,
    fanQuantity: fanQuantity,
    alv2Hardware: alv2Hardware,
    alv2Merge: json['alv2Merge'] is bool ? json['alv2Merge'] as bool : false,
    alv2MergeMode: mergeMode is String && mergeMode.isNotEmpty
        ? mergeMode
        : 'Runway',
    alv2MergeOrder:
        mergeOrder is List && LightingConfig.isMergeOrder(mergeOrder)
        ? mergeOrder.cast<int>()
        : LightingConfig.defaultMergeOrder,
    boardZones: boardZones,
    gpuHardware: decodeGpuHardwareConfig(json['gpuHardware']),
  );
}

JsonMap encodeLightingConfig(LightingConfig config) => {
  'argbOff': config.argbOff,
  'brightness': config.brightness,
  'offOnSleep': config.offOnSleep,
  'autoHardware': config.autoHardware,
  'effectId': config.effectId,
  'effectValues': config.effectValues,
  'devices': {
    for (final id in LightDeviceId.values)
      id.name: encodeDeviceLightConfig(config.device(id)),
  },
  'fanQuantity': config.fanQuantity,
  'alv2Hardware': [
    for (final hardware in config.alv2Hardware)
      encodeAlv2HardwareConfig(hardware),
  ],
  'alv2Merge': config.alv2Merge,
  'alv2MergeMode': config.alv2MergeMode,
  'alv2MergeOrder': config.alv2MergeOrder,
  'boardZones': {
    for (final entry in config.boardZones.entries)
      _zoneKey(entry.key): encodeBoardZoneConfig(entry.value),
  },
  'gpuHardware': encodeGpuHardwareConfig(config.gpuHardware),
};

Alv2HardwareConfig decodeAlv2HardwareConfig(Object? json) {
  const defaults = Alv2HardwareConfig();
  if (json is! Map) return defaults;
  final mode = json['mode'];
  final colors = json['colors'];
  return Alv2HardwareConfig(
    scope:
        Alv2Scope.values.where((s) => s.name == json['scope']).firstOrNull ??
        defaults.scope,
    mode: mode is String && mode.isNotEmpty ? mode : defaults.mode,
    speed: _level(json['speed'], 4, defaults.speed),
    brightness: _level(json['brightness'], 4, defaults.brightness),
    directionLeft: json['directionLeft'] is bool
        ? json['directionLeft'] as bool
        : defaults.directionLeft,
    colors: colors is List
        ? List.unmodifiable([
            for (final color in colors)
              ?(color is String ? Rgb.parse(color) : null),
          ])
        : defaults.colors,
  );
}

JsonMap encodeAlv2HardwareConfig(Alv2HardwareConfig config) => {
  'scope': config.scope.name,
  'mode': config.mode,
  'speed': config.speed,
  'brightness': config.brightness,
  'directionLeft': config.directionLeft,
  'colors': [for (final color in config.colors) color.toHex()],
};

BoardZoneConfig decodeBoardZoneConfig(Object? json) {
  const defaults = BoardZoneConfig();
  if (json is! Map) return defaults;
  return BoardZoneConfig(
    mode:
        BoardEffectMode.values
            .where((m) => m.name == json['mode'])
            .firstOrNull ??
        defaults.mode,
    color:
        (json['color'] is String ? Rgb.parse(json['color'] as String) : null) ??
        defaults.color,
    speed: _level(json['speed'], 9, defaults.speed),
    brightness: _level(json['brightness'], 9, defaults.brightness),
  );
}

JsonMap encodeBoardZoneConfig(BoardZoneConfig config) => {
  'mode': config.mode.name,
  'color': config.color.toHex(),
  'speed': config.speed,
  'brightness': config.brightness,
};

GpuHardwareConfig decodeGpuHardwareConfig(Object? json) {
  const defaults = GpuHardwareConfig();
  if (json is! Map) return defaults;
  final colors = json['colors'];
  return GpuHardwareConfig(
    effect:
        GpuEffect.values.where((e) => e.name == json['effect']).firstOrNull ??
        defaults.effect,
    speed: _level(json['speed'], 10, defaults.speed),
    brightness: _level(json['brightness'], 10, defaults.brightness),
    color:
        (json['color'] is String ? Rgb.parse(json['color'] as String) : null) ??
        defaults.color,
    colors: colors is List && colors.isNotEmpty
        ? List.unmodifiable([
            for (final color in colors)
              ?(color is String ? Rgb.parse(color) : null),
          ])
        : defaults.colors,
  );
}

JsonMap encodeGpuHardwareConfig(GpuHardwareConfig config) => {
  'effect': config.effect.name,
  'speed': config.speed,
  'brightness': config.brightness,
  'color': config.color.toHex(),
  'colors': [for (final color in config.colors) color.toHex()],
};

DeviceLightConfig decodeDeviceLightConfig(LightDeviceId id, Object? json) {
  final defaults = DeviceLightConfig.defaults(id);
  if (json is! Map || !id.isSupported) return defaults;
  final mode = LightMode.values
      .where((m) => m.name == json['mode'])
      .firstOrNull;
  return DeviceLightConfig(
    enabled: json['enabled'] is bool
        ? json['enabled'] as bool
        : defaults.enabled,
    mode: mode != null && id.accepts(mode) ? mode : defaults.mode,
    fixedColor:
        (json['fixedColor'] is String
            ? Rgb.parse(json['fixedColor'] as String)
            : null) ??
        defaults.fixedColor,
    placement: CanvasRect.fromJson(json['placement'], defaults.placement),
  );
}

JsonMap encodeDeviceLightConfig(DeviceLightConfig config) => {
  'enabled': config.enabled,
  'mode': config.mode.name,
  'fixedColor': config.fixedColor.toHex(),
  'placement': config.placement.toJson(),
};

String _zoneKey(int zone) => '0x${zone.toRadixString(16).toUpperCase()}';

int _level(Object? value, int max, int fallback) =>
    value is int ? value.clamp(0, max) : fallback;
