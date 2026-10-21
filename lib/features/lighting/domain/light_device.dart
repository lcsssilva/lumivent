// Lighting module domain (pure Dart): lighting devices and modes.

/// Devices controlled by the lighting screen.
enum LightDeviceId {
  alv2Group1('Fans · Grupo 1', 1),
  alv2Group2('Fans · Grupo 2', 2),
  alv2Group3('Fans · Grupo 3', 3),
  chassis('Gabinete'),
  motherboard('Placa-mãe'),
  ram1('Memória 1'),
  ram2('Memória 2'),
  gpu('Placa de vídeo');

  const LightDeviceId(this.label, [this.hubGroup]);

  /// Name for the UI.
  final String label;

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
  canvas('Canvas'),

  /// Device-owned modes (firmware modes on fans, motherboard effects).
  hardware('Hardware'),

  /// A single color.
  fixed('Cor fixa');

  const LightMode(this.label);
  final String label;
}
