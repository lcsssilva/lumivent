import 'package:freezed_annotation/freezed_annotation.dart';

import '../rgb.dart';
import 'lighting_config.dart';

part 'board_zone_config.freezed.dart';

@freezed
abstract class BoardZoneConfig with _$BoardZoneConfig {
  const factory BoardZoneConfig({
    @Default(BoardEffectMode.static) BoardEffectMode mode,
    @Default(Rgb.white) Rgb color,

    /// 0–9.
    @Default(5) int speed,

    /// 0–9.
    @Default(9) int brightness,
  }) = _BoardZoneConfig;
}
