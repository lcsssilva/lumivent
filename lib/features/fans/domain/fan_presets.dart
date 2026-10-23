import 'fan_curve.dart';
import 'fan_point.dart';

abstract final class FanPresets {
  /// Limit for editable points (not counting automatic endpoints).
  static const maxPoints = 8;

  static const defaultFixedPercent = 50.0;

  // `Ene6K77FanProfile.defaultPhaseData` (AL-V2 §5).
  static const quiet = [
    FanPoint(25, 20),
    FanPoint(45, 45),
    FanPoint(65, 52),
    FanPoint(80, 75),
    FanPoint(90, 100),
  ];
  static const standard = [
    FanPoint(25, 20),
    FanPoint(40, 50),
    FanPoint(55, 62),
    FanPoint(70, 75),
    FanPoint(90, 100),
  ];
  static const high = [
    FanPoint(25, 45),
    FanPoint(35, 55),
    FanPoint(50, 70),
    FanPoint(70, 85),
    FanPoint(85, 100),
  ];
  static const full = [
    FanPoint(25, 100),
    FanPoint(40, 100),
    FanPoint(55, 100),
    FanPoint(70, 100),
    FanPoint(90, 100),
  ];

  /// Factory points for a preset. UserDefine 1–4 start equal to Quiet;
  /// [FanPreset.fixed] and [FanPreset.custom] have no factory points.
  static List<FanPoint> defaults(FanPreset p) => switch (p) {
    FanPreset.quiet ||
    FanPreset.user1 ||
    FanPreset.user2 ||
    FanPreset.user3 ||
    FanPreset.user4 => quiet,
    FanPreset.standard => standard,
    FanPreset.high => high,
    FanPreset.full => full,
    FanPreset.fixed || FanPreset.custom => standard,
  };
}
