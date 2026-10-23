import 'package:lumivent/features/fans/fans.dart';

class FakeTemps implements FanTemperatures {
  final values = <FanTempSource, double?>{};

  @override
  double? read(FanTempSource source) => values[source];
}
