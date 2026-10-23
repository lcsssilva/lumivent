import 'lighting_strings.dart';

class LightingStringsEn extends LightingStrings {
  const LightingStringsEn();

  @override
  String get devices => 'Devices';
  @override
  String get previousDevices => 'Previous devices';
  @override
  String get nextDevices => 'Next devices';
  @override
  String fansGroup(String name) => 'Fans · $name';
  @override
  String get chassis => 'Case';
  @override
  String get motherboard => 'Motherboard';
  @override
  String get memory1 => 'Memory 1';
  @override
  String get memory2 => 'Memory 2';
  @override
  String get graphicsCard => 'Graphics card';
  @override
  String get modeCanvas => 'Canvas';
  @override
  String get modeHardware => 'Hardware';
  @override
  String get modeFixed => 'Solid color';
  @override
  String effectLabel(String id, String fallback) => switch (id) {
    'solid' => 'Solid color',
    'spectrum' => 'Color cycle',
    'rainbowWave' => 'Rainbow wave',
    'breathing' => 'Breathing',
    'colorWave' => 'Two-color wave',
    'scanner' => 'Scanner',
    _ => fallback,
  };
  @override
  String paramLabel(String id, String fallback) => switch (id) {
    'speed' => 'Speed',
    'size' => 'Wave size',
    'direction' => 'Direction',
    'color' => 'Color',
    'color2' => 'Color 2',
    'background' => 'Background',
    'width' => 'Width',
    _ => fallback,
  };
  @override
  String optionLabel(String value) => switch (value) {
    'Left' => 'Left',
    'Right' => 'Right',
    'Up' => 'Up',
    'Down' => 'Down',
    _ => value,
  };
  @override
  String get unsupported => 'Unsupported';
  @override
  String get waitingStatus => 'Waiting for device status';
  @override
  String get working => 'Working';
  @override
  String get unavailable => 'Unavailable';
  @override
  String get autoHardware => 'Hardware (auto)';
  @override
  String get allArgbOff => 'All ARGB is turned off';
  @override
  String get turnOn => 'Turn on';
  @override
  String get brightness => 'Brightness';
  @override
  String get offOnSleep => 'Turn off when suspending or shutting down';
  @override
  String get useHardwareEffects => 'Use the hardware effects when possible';
  @override
  String get hardwareEffectsHint =>
      'Fans and the motherboard animate the effect in their own firmware, with '
      'smoother motion. The phase between devices may not be identical. For '
      'effects without an equivalent, and without this option, the fans get 2 '
      'frames per second: any faster and their speed oscillates.';
  @override
  String get effectLibrary => 'Effect library';
  @override
  String get importEffectsHint => 'Import HTML effects in the Explore tab.';
  @override
  String canvasSize(int width, int height) => 'Canvas $width×$height';
  @override
  String get effect => 'Effect';
  @override
  String get noControls => 'This effect has no available controls.';
  @override
  String effectTitle(String name) => 'Effect: $name';
  @override
  String get loadingEffects => 'Loading installed effects…';
  @override
  String libraryError(String error) =>
      'Could not read the library.\nTechnical details: $error';
  @override
  String get effectNotInstalled =>
      'This effect is not installed. Import it in the Explore tab.';
  @override
  String get fixedSpeedNotice => 'Fixed speed on the fans (firmware mode).';
  @override
  String htmlStats(String fps, String ms) => '$fps fps · $ms ms/frame';
  @override
  String fixedColorTitle(String device) => 'Solid color · $device';
  @override
  String effectLoadFailed(String error) =>
      'Could not load the effect.\nTechnical details: $error';
  @override
  String effectPaused(int ms) => 'Effect paused: frame took $ms ms.';
  @override
  String effectUnsupported(String issues) => 'Effect not supported: $issues.';
  @override
  String get compatible => 'Compatible';
  @override
  String get partial => 'Partial';
  @override
  String get unsupportedEffect => 'Unsupported';
  @override
  String get compatCapture => 'screen capture';
  @override
  String get compatPixels => 'pixel reads';
  @override
  String get compatAudio => 'audio (silence)';
  @override
  String get compatImages => 'images';
  @override
  String get compatApi => 'unsupported API';
  @override
  String get requiresIssues => 'Requires';
  @override
  String get argb => 'ARGB';
  @override
  String get argbOff => 'ARGB off';
  @override
  String get turnOnAllArgb => 'Turn on all ARGB';
  @override
  String get turnOffAllArgb => 'Turn off all ARGB';
  @override
  String hardwareTitle(String device) => 'Hardware · $device';
  @override
  String get identify => 'Identify';
  @override
  String get wholeFan => 'Whole fan';
  @override
  String get innerOuter => 'Inner + outer';
  @override
  String get mode => 'Mode';
  @override
  String get mergeActive =>
      'Merge active: the group mode is replaced by the merge mode.';
  @override
  String get fansInGroup => 'Fans in the group';
  @override
  String get mergeBetweenGroups => 'Merge between groups';
  @override
  String get mergeMode => 'Merge mode';
  @override
  String get mergeOrder => 'Merge order';
  @override
  String get mergeShared => 'Merge settings apply to every group.';
  @override
  String get speed => 'Speed';
  @override
  String get direction => 'Direction';
  @override
  String get right => 'Right';
  @override
  String get left => 'Left';
  @override
  String get colors => 'Colors';
  @override
  String colorsCount(int count) => 'Colors ($count)';
  @override
  String get color => 'Color';
  @override
  String get gpuNote =>
      'The controller accepts one effect every 120 ms. The app only sends '
      'colors after reading the card SSID; if the OEM read fails, the GPU is '
      'unavailable.';
  @override
  String get boardHardwareTitle => 'Hardware · Motherboard';
  @override
  String get boardModeStatic => 'Static';
  @override
  String get boardModePulse => 'Pulse';
  @override
  String get boardModeFlash => 'Flash';
  @override
  String get boardModeDoubleFlash => 'Double flash';
  @override
  String get boardModeColorCycle => 'Color cycle';
  @override
  String get boardModeWave => 'Wave';
  @override
  String boardZone(int zone) => switch (zone) {
    0x20 => 'IO Shield 1',
    0x22 => 'CPU LED',
    0x23 => 'IO Shield 2',
    _ => 'Zone $zone',
  };
  @override
  String get gpuEffectOff => 'Off';
  @override
  String get gpuEffectStatic => 'Static';
  @override
  String get gpuEffectBreathing => 'Breathing';
  @override
  String get gpuEffectFlash => 'Flash';
  @override
  String get gpuEffectDoubleFlash => 'Double flash';
  @override
  String get gpuEffectColorCycle => 'Color cycle';
  @override
  String get gpuEffectWave => 'Wave';
  @override
  String get gpuEffectGradient => 'Gradient';
  @override
  String get gpuEffectColorShift => 'Color shift';
  @override
  String get gpuEffectRainbow => 'Rainbow';
  @override
  String get gpuEffectThreeColors => 'Three colors';
  @override
  String get gpuEffectClaws => 'Claws';
  @override
  String get gpuEffectDazzle => 'Dazzle';
  @override
  String get chooseColor => 'Choose color';
  @override
  String get hexadecimal => 'Hexadecimal';
  @override
  String get outputUnsupported =>
      'The graphics card driver is not available yet.';
  @override
  String get outputHub => 'AL V2 hub not found or without access permission.';
  @override
  String get outputIte =>
      'Motherboard ITE controller not found or without access permission.';
  @override
  String outputGpu(List<String> args) => args.isEmpty
      ? 'GPU RGB controller not found or without access permission.'
      : 'GPU RGB controller not found or without access permission: '
            '${args.join(', ')}';
  @override
  String get outputRam =>
      'Kingston Fury memory not found or without access permission on the '
      'SMBus.';
  @override
  String outputBlocked(List<String> args) =>
      'Blocked for safety: ${args.join(', ')}';
}
