// User-facing names for the fans screen. The catalogs own the text; this file
// only maps domain values to the matching catalog entry.
import '../../../core/i18n/app_strings.dart';
import '../domain/fan_curve.dart';
import '../domain/fan_group.dart';
import '../domain/fan_group_config.dart';
import '../domain/fan_response.dart';

/// Display name of [g], falling back to the catalog's default group name.
String fanGroupLabel(AppStrings strings, FanGroupConfig g) =>
    g.name.trim().isEmpty ? strings.common.groupName(g.group) : g.name;

/// Short label of a curve preset.
String fanPresetLabel(AppStrings strings, FanPreset p) => switch (p) {
  FanPreset.quiet => strings.fans.presetQuiet,
  FanPreset.standard => strings.fans.presetStandard,
  FanPreset.high => strings.fans.presetHigh,
  FanPreset.full => strings.fans.presetFull,
  FanPreset.fixed => strings.fans.presetFixed,
  FanPreset.user1 => strings.fans.presetUser1,
  FanPreset.user2 => strings.fans.presetUser2,
  FanPreset.user3 => strings.fans.presetUser3,
  FanPreset.user4 => strings.fans.presetUser4,
  FanPreset.custom => strings.fans.presetCustom,
};

/// Label of a temperature source.
String fanSourceLabel(AppStrings strings, FanTempSource s) => switch (s) {
  FanTempSource.cpuTctl => strings.fans.sourceCpuTctl,
  FanTempSource.gpuJunction => strings.fans.sourceGpuJunction,
  FanTempSource.gpuEdge => strings.fans.sourceGpuEdge,
  FanTempSource.boardSystem1 => strings.fans.sourceSystem1,
  FanTempSource.boardSystem2 => strings.fans.sourceSystem2,
  FanTempSource.boardPch => strings.fans.sourcePch,
  FanTempSource.boardCpuSocket => strings.fans.sourceCpuSocket,
  FanTempSource.boardVrm => strings.fans.sourceVrm,
  FanTempSource.boardPciex16 => strings.fans.sourcePciex16,
  FanTempSource.boardPciex4 => strings.fans.sourcePciex4,
};

/// Name in the source list: motherboard sensors are grouped under "Motherboard".
String fanSourceMenuLabel(AppStrings strings, FanTempSource s) => s.isBoard
    ? '${strings.fans.motherboardPrefix} · ${fanSourceLabel(strings, s)}'
    : fanSourceLabel(strings, s);

/// Short label of a fan response mode.
String fanResponseLabel(AppStrings strings, FanResponse r) => switch (r) {
  FanResponse.fast => strings.fans.responseFast,
  FanResponse.normal => strings.fans.responseNormal,
  FanResponse.smooth => strings.fans.responseSmooth,
};

/// Hint of a fan response mode.
String fanResponseHint(AppStrings strings, FanResponse r) => switch (r) {
  FanResponse.fast => strings.fans.responseFastHint,
  FanResponse.normal => strings.fans.responseNormalHint,
  FanResponse.smooth => strings.fans.responseSmoothHint,
};
