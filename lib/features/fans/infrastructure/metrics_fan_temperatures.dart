import '../../monitoring/monitoring.dart' show Metrics, SensorSample;
import '../domain/fan_group.dart';

/// Curve temperatures from the latest monitoring reading.
class MetricsFanTemperatures implements FanTemperatures {
  MetricsFanTemperatures(this._latest);

  /// Latest sensor sample (`null` before the first reading).
  final SensorSample? Function() _latest;

  // Board sensors, in the order of `Metrics.boardTemps` (protocol notes §2.5).
  static final _system1 = Metrics.boardTemps[0].id;
  static final _pch = Metrics.boardTemps[1].id;
  static final _cpuSocket = Metrics.boardTemps[2].id;
  static final _pciex16 = Metrics.boardTemps[3].id;
  static final _vrm = Metrics.boardTemps[4].id;
  static final _pciex4 = Metrics.boardTemps[6].id;
  static final _system2 = Metrics.boardTemps[8].id;

  @override
  double? read(FanTempSource source) =>
      _latest()?.values[switch (source) {
        FanTempSource.cpuTctl => Metrics.cpuTctl,
        FanTempSource.gpuJunction => Metrics.gpuJunction,
        FanTempSource.gpuEdge => Metrics.gpuEdge,
        FanTempSource.boardSystem1 => _system1,
        FanTempSource.boardSystem2 => _system2,
        FanTempSource.boardPch => _pch,
        FanTempSource.boardCpuSocket => _cpuSocket,
        FanTempSource.boardVrm => _vrm,
        FanTempSource.boardPciex16 => _pciex16,
        FanTempSource.boardPciex4 => _pciex4,
      }];
}
