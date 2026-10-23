import 'fans_strings.dart';

class FansStringsEn extends FansStrings {
  const FansStringsEn();

  @override
  String get presetQuiet => 'Quiet';
  @override
  String get presetStandard => 'Standard';
  @override
  String get presetHigh => 'High';
  @override
  String get presetFull => 'Full';
  @override
  String get presetFixed => 'Fixed';
  @override
  String get presetUser1 => 'User 1';
  @override
  String get presetUser2 => 'User 2';
  @override
  String get presetUser3 => 'User 3';
  @override
  String get presetUser4 => 'User 4';
  @override
  String get presetCustom => 'Custom';
  @override
  String get sourceCpuTctl => 'CPU Tctl';
  @override
  String get sourceGpuJunction => 'GPU junction';
  @override
  String get sourceGpuEdge => 'GPU edge';
  @override
  String get sourceSystem1 => 'System 1';
  @override
  String get sourceSystem2 => 'System 2';
  @override
  String get sourcePch => 'PCH';
  @override
  String get sourceCpuSocket => 'CPU socket';
  @override
  String get sourceVrm => 'VRM';
  @override
  String get sourcePciex16 => 'PCIEX16';
  @override
  String get sourcePciex4 => 'PCIEX4';
  @override
  String get motherboardPrefix => 'Motherboard';
  @override
  String get responseFast => 'Fast';
  @override
  String get responseNormal => 'Normal';
  @override
  String get responseSmooth => 'Smooth';
  @override
  String get responseFastHint =>
      'No average or ramp: the fan follows the temperature every second.';
  @override
  String get responseNormalHint =>
      '4 s average; rises up to 15%/s and falls 3%/s to avoid Tctl spikes.';
  @override
  String get responseSmoothHint =>
      '10 s average; rises up to 5%/s and falls 1%/s for quiet fans.';
  @override
  String get groupsTitle => 'AL V2 hub groups';
  @override
  String applyAllTooltip(String name) =>
      'Copies the preset, points, Start/Stop, source, and response from '
      '"$name" to the other groups.';
  @override
  String applyAllLabel(String name) => 'Apply curve "$name" to all';
  @override
  String appliedToAll(String name) => 'Curve "$name" applied to all groups.';
  @override
  String get speedCurve => 'Fan curve';
  @override
  String get dragFixedHint =>
      'Drag the point up or down to change the fixed speed.';
  @override
  String dragHint(int maxPoints) =>
      'Drag the points · double-click adds (max. $maxPoints) · right-click '
      'removes.';
  @override
  String get groupOptions => 'Group options';
  @override
  String get startStop => 'Start/Stop';
  @override
  String get startStopHint =>
      'Stops the fans below the temperature of the first point.';
  @override
  String get temperatureSource => 'Temperature source';
  @override
  String get temperatureSourceHint =>
      'CPU/GPU for radiators; motherboard temperature (System, VRM…) for case '
      'fans.';
  @override
  String get temperatureResponse => 'Temperature response';
  @override
  String nowTemperature(String temperature) => '(now $temperature)';
  @override
  String get noTemperature => 'No temperature';
  @override
  String get hubUnavailable => 'Hub unavailable';
  @override
  String get noFan => 'no fan';
  @override
  String get groupName => 'Group name';
  @override
  String get currentRpm => 'Current RPM';
  @override
  String get duty => 'Duty';
  @override
  String get target => 'Target';
  @override
  String dutyAndRpm(String duty, String rpm) => 'duty $duty % · $rpm rpm';
}
