/// Lighting page: devices, modes, effects, panels, and effect compatibility.
abstract class LightingStrings {
  const LightingStrings();

  // Device strip.
  String get devices;
  String get previousDevices;
  String get nextDevices;
  String fansGroup(String name);
  String get chassis;
  String get motherboard;
  String get memory1;
  String get memory2;
  String get graphicsCard;

  // Modes.
  String get modeCanvas;
  String get modeHardware;
  String get modeFixed;

  // Native effects and parameters.
  String effectLabel(String id, String fallback);
  String paramLabel(String id, String fallback);

  /// Native combobox values (`Left`, `Right`, `Up`, `Down`); other values pass
  /// through unchanged (HTML effects own their option text).
  String optionLabel(String value);

  // Device status.
  String get unsupported;
  String get waitingStatus;
  String get working;
  String get unavailable;
  String get autoHardware;

  // Global banner and controls.
  String get allArgbOff;
  String get turnOn;
  String get brightness;
  String get offOnSleep;
  String get useHardwareEffects;
  String get hardwareEffectsHint;
  String get effectLibrary;
  String get importEffectsHint;
  String canvasSize(int width, int height);

  // Effect panel.
  String get effect;
  String get noControls;
  String effectTitle(String name);
  String get loadingEffects;
  String libraryError(String error);
  String get effectNotInstalled;
  String get fixedSpeedNotice;
  String htmlStats(String fps, String ms);
  String fixedColorTitle(String device);
  String effectLoadFailed(String error);
  String effectPaused(int ms);
  String effectUnsupported(String issues);

  // Compatibility.
  String get compatible;
  String get partial;
  String get unsupportedEffect;
  String get compatCapture;
  String get compatPixels;
  String get compatAudio;
  String get compatImages;
  String get compatApi;
  String get requiresIssues;

  // ARGB toggle.
  String get argb;
  String get argbOff;
  String get turnOnAllArgb;
  String get turnOffAllArgb;

  // Hardware panels.
  String hardwareTitle(String device);
  String get identify;
  String get wholeFan;
  String get innerOuter;
  String get mode;
  String get mergeActive;
  String get fansInGroup;
  String get mergeBetweenGroups;
  String get mergeMode;
  String get mergeOrder;
  String get mergeShared;
  String get speed;
  String get direction;
  String get right;
  String get left;
  String get colors;
  String colorsCount(int count);
  String get color;
  String get gpuNote;
  String get boardHardwareTitle;
  String get boardModeStatic;
  String get boardModePulse;
  String get boardModeFlash;
  String get boardModeDoubleFlash;
  String get boardModeColorCycle;
  String get boardModeWave;
  String boardZone(int zone);

  // GPU effects.
  String get gpuEffectOff;
  String get gpuEffectStatic;
  String get gpuEffectBreathing;
  String get gpuEffectFlash;
  String get gpuEffectDoubleFlash;
  String get gpuEffectColorCycle;
  String get gpuEffectWave;
  String get gpuEffectGradient;
  String get gpuEffectColorShift;
  String get gpuEffectRainbow;
  String get gpuEffectThreeColors;
  String get gpuEffectClaws;
  String get gpuEffectDazzle;

  // Color picker.
  String get chooseColor;
  String get hexadecimal;

  // Output status details.
  String get outputUnsupported;
  String get outputHub;
  String get outputIte;
  String outputGpu(List<String> args);
  String get outputRam;
  String outputBlocked(List<String> args);
}
