// Lighting module domain (pure Dart): lighting devices and modes.

/// Devices controlled by the lighting screen.
enum LightDeviceId {
  alv2Group1(1),
  alv2Group2(2),
  alv2Group3(3),
  chassis,
  motherboard,
  ram1,
  ram2,
  gpu;

  const LightDeviceId([this.hubGroup]);

  /// Group (port) of the AL V2 hub, 1–3; `null` outside fans. Group 0 of the hub
  /// is empty and always off (AL-V2 §8).
  final int? hubGroup;

  bool get isFan => hubGroup != null;
  bool get isRam => this == ram1 || this == ram2;

  /// Modes accepted by the device.
  Set<LightMode> get supportedModes => switch (this) {
    alv2Group1 ||
    alv2Group2 ||
    alv2Group3 ||
    motherboard ||
    gpu => const {LightMode.canvas, LightMode.hardware, LightMode.fixed},
    chassis || ram1 || ram2 => const {LightMode.canvas, LightMode.fixed},
  };

  bool get isSupported => supportedModes.isNotEmpty;

  bool accepts(LightMode mode) => supportedModes.contains(mode);

  /// Device of hub group [group] (1–3), or `null`.
  static LightDeviceId? forHubGroup(int group) =>
      LightDeviceId.values.where((d) => d.hubGroup == group).firstOrNull;
}

/// Who decides the device color.
enum LightMode {
  /// Follows the global effect, sampled at the LEDs' canvas positions.
  canvas,

  /// Device-owned modes (firmware modes on fans, motherboard effects).
  hardware,

  /// A single color.
  fixed,
}
