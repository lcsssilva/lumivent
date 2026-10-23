import '../../devices/devices.dart' show Alv2LightMode, Alv2LightScope;
import '../domain/hardware_mode/fan_hardware_mode.dart';
import '../domain/hardware_mode/fan_mode_name.dart';

/// The AL V2 driver's mode table as the settings the user configures, without
/// the firmware codes.
final List<FanHardwareMode> alv2FanHardwareModes = List.unmodifiable([
  for (final mode in Alv2LightMode.values)
    FanHardwareMode(
      name: mode.firmwareName,
      scope: switch (mode.scope) {
        Alv2LightScope.whole => null,
        Alv2LightScope.inner => FanModeSuffix.inner,
        Alv2LightScope.outer => FanModeSuffix.outer,
        Alv2LightScope.merge => FanModeSuffix.merge,
      },
      hasSpeed: mode.hasSpeed,
      hasDirection: mode.hasDirection,
      colorCount: mode.colorCount,
    ),
]);
