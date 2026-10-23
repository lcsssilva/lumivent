import 'fan_group.dart';

/// Temperatures the curve can follow, read by the engine. `null` = no reading.
abstract interface class FanTemperatures {
  double? read(FanTempSource source);
}
