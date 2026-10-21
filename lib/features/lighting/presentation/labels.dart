// User-facing names for the lighting screen. The catalogs own the text; this
// file only maps domain values to the matching catalog entry.

import '../../../core/i18n/app_strings.dart';
import '../domain/light_device.dart';
import '../domain/lighting_config.dart';

/// [fanNames]: names of the hub groups 0–3 (`fanGroupNamesProvider`).
String deviceLabel(
  AppStrings strings,
  LightDeviceId id, [
  List<String> fanNames = const [],
]) => switch (id) {
  _ when id.isFan => strings.lighting.fansGroup(
    fanGroupName(strings, id.hubGroup!, fanNames),
  ),
  LightDeviceId.chassis => strings.lighting.chassis,
  LightDeviceId.motherboard => strings.lighting.motherboard,
  LightDeviceId.ram1 => strings.lighting.memory1,
  LightDeviceId.ram2 => strings.lighting.memory2,
  LightDeviceId.gpu => strings.lighting.graphicsCard,
  _ => id.name,
};

/// Name of hub group [group] (0–3), the catalog's default when unnamed.
String fanGroupName(AppStrings strings, int group, List<String> fanNames) {
  final name = group < fanNames.length ? fanNames[group].trim() : '';
  return name.isEmpty ? strings.common.groupName(group) : name;
}

String modeLabel(AppStrings strings, LightMode m) => switch (m) {
  LightMode.canvas => strings.lighting.modeCanvas,
  LightMode.hardware => strings.lighting.modeHardware,
  LightMode.fixed => strings.lighting.modeFixed,
};

String effectLabel(AppStrings strings, String id, String fallback) =>
    strings.lighting.effectLabel(id, fallback);

String paramLabel(AppStrings strings, String id, String fallback) =>
    strings.lighting.paramLabel(id, fallback);

String boardModeLabel(AppStrings strings, BoardEffectMode m) =>
    strings.lighting.boardMode(m.index);

String boardZoneLabel(AppStrings strings, int zone) =>
    strings.lighting.boardZone(zone);

String gpuEffectLabel(AppStrings strings, GpuEffect effect) =>
    strings.lighting.gpuEffect(effect.index);

/// Readable firmware mode name: `RainbowMorph_Inner` -> `Rainbow Morph`.
String firmwareModeLabel(String name) {
  final base = name.split('_').first;
  return base
      .replaceAllMapped(RegExp(r'(?<=[a-z])(?=[A-Z])'), (_) => ' ')
      .trim();
}
