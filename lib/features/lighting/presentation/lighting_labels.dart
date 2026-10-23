// User-facing names for the lighting screen. The catalogs own the text; this
// file only maps domain values to the matching catalog entry.

import '../../../core/i18n/app_strings.dart';
import '../application/status/light_output_state.dart' show LightOutputIssue;
import '../domain/effects/effect_compatibility.dart' show EffectIssue;
import '../domain/hardware_mode/fan_mode_name.dart';
import '../domain/light_device.dart';
import '../domain/config/lighting_config.dart';

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

String boardModeLabel(AppStrings strings, BoardEffectMode mode) {
  final l = strings.lighting;
  return switch (mode) {
    BoardEffectMode.static => l.boardModeStatic,
    BoardEffectMode.pulse => l.boardModePulse,
    BoardEffectMode.flash => l.boardModeFlash,
    BoardEffectMode.doubleFlash => l.boardModeDoubleFlash,
    BoardEffectMode.colorCycle => l.boardModeColorCycle,
    BoardEffectMode.wave => l.boardModeWave,
  };
}

String boardZoneLabel(AppStrings strings, int zone) =>
    strings.lighting.boardZone(zone);

String gpuEffectLabel(AppStrings strings, GpuEffect effect) {
  final l = strings.lighting;
  return switch (effect) {
    GpuEffect.off => l.gpuEffectOff,
    GpuEffect.staticColor => l.gpuEffectStatic,
    GpuEffect.pulse => l.gpuEffectBreathing,
    GpuEffect.flash => l.gpuEffectFlash,
    GpuEffect.doubleFlash => l.gpuEffectDoubleFlash,
    GpuEffect.cycle => l.gpuEffectColorCycle,
    GpuEffect.wave => l.gpuEffectWave,
    GpuEffect.gradient => l.gpuEffectGradient,
    GpuEffect.colorShift => l.gpuEffectColorShift,
    GpuEffect.rainbow => l.gpuEffectRainbow,
    GpuEffect.tricolor => l.gpuEffectThreeColors,
    GpuEffect.claws => l.gpuEffectClaws,
    GpuEffect.dazzle => l.gpuEffectDazzle,
  };
}

/// Feature an HTML effect needs that the host does not provide.
String effectIssueLabel(AppStrings strings, EffectIssue issue) {
  final l = strings.lighting;
  return switch (issue) {
    EffectIssue.capture => l.compatCapture,
    EffectIssue.pixels => l.compatPixels,
    EffectIssue.audio => l.compatAudio,
    EffectIssue.images => l.compatImages,
    EffectIssue.api => l.compatApi,
  };
}

/// Why a device has no output; [args] carries the technical details.
String outputIssueLabel(
  AppStrings strings,
  LightOutputIssue issue,
  List<String> args,
) {
  final l = strings.lighting;
  return switch (issue) {
    LightOutputIssue.unsupported => l.outputUnsupported,
    LightOutputIssue.hub => l.outputHub,
    LightOutputIssue.ite => l.outputIte,
    LightOutputIssue.gpu => l.outputGpu(args),
    LightOutputIssue.ram => l.outputRam,
    LightOutputIssue.blocked => l.outputBlocked(args),
  };
}

/// Readable firmware mode name: `RainbowMorph_Inner` -> `Rainbow Morph`.
String firmwareModeLabel(String name) {
  final base = fanModeBase(name);
  return base
      .replaceAllMapped(RegExp(r'(?<=[a-z])(?=[A-Z])'), (_) => ' ')
      .trim();
}
