/// Fans page: presets, temperature sources, response, groups, and curve editor.
abstract class FansStrings {
  const FansStrings();

  // Presets.
  String get presetQuiet;
  String get presetStandard;
  String get presetHigh;
  String get presetFull;
  String get presetFixed;
  String get presetUser1;
  String get presetUser2;
  String get presetUser3;
  String get presetUser4;
  String get presetCustom;

  // Temperature sources.
  String get sourceCpuTctl;
  String get sourceGpuJunction;
  String get sourceGpuEdge;
  String get sourceSystem1;
  String get sourceSystem2;
  String get sourcePch;
  String get sourceCpuSocket;
  String get sourceVrm;
  String get sourcePciex16;
  String get sourcePciex4;

  /// Prefix for motherboard sources in the source list.
  String get motherboardPrefix;

  // Temperature response.
  String get responseFast;
  String get responseNormal;
  String get responseSmooth;
  String get responseFastHint;
  String get responseNormalHint;
  String get responseSmoothHint;

  // Page.
  String get groupsTitle;
  String applyAllTooltip(String name);
  String applyAllLabel(String name);
  String appliedToAll(String name);
  String get speedCurve;
  String get dragFixedHint;
  String dragHint(int maxPoints);
  String get groupOptions;
  String get startStop;
  String get startStopHint;
  String get temperatureSource;
  String get temperatureSourceHint;
  String get temperatureResponse;

  // Live values.
  String nowTemperature(String temperature);
  String get noTemperature;
  String get hubUnavailable;
  String get noFan;
  String get groupName;
  String get currentRpm;
  String get duty;
  String get target;
  String dutyAndRpm(String duty, String rpm);
}
