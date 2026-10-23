import 'fan_mode_name.dart';

/// A firmware lighting mode of the AL V2 fan hub as the user configures it:
/// its name, the scope it applies to, and which settings it accepts. The
/// firmware codes stay in the devices driver.
class FanHardwareMode {
  const FanHardwareMode({
    required this.name,
    this.scope,
    this.hasSpeed = false,
    this.hasDirection = false,
    this.colorCount = 0,
  });

  /// Firmware mode name (`Rainbow`, `StaticColor_Inner`, `Runway_Merge`).
  final String name;

  /// Ring or merge variant; `null` for a whole-fan mode.
  final FanModeSuffix? scope;

  final bool hasSpeed;
  final bool hasDirection;

  /// How many colors the user picks for the mode.
  final int colorCount;
}

/// Lookups over the modes a hub offers.
extension FanHardwareModes on Iterable<FanHardwareMode> {
  /// The mode named [name], or `null` when the firmware has none.
  FanHardwareMode? byName(String name) {
    for (final mode in this) {
      if (mode.name == name) return mode;
    }
    return null;
  }

  /// Names of the modes of [scope] (`null`: whole fan), in table order.
  List<String> namesOf(FanModeSuffix? scope) => [
    for (final mode in this)
      if (mode.scope == scope) mode.name,
  ];

  /// Base names (`Runway`) of the merge modes, as the config stores them.
  List<String> get mergeBases => [
    for (final name in namesOf(FanModeSuffix.merge)) mergeModeBase(name),
  ];
}
