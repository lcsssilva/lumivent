import '../../monitoring/monitoring.dart' show Metrics;
import '../domain/fan_group.dart';

/// Monitoring metric ID that carries the temperature of [source]. The single
/// source-to-metric mapping, shared by the engine reader and the fans page.
String fanTempMetric(FanTempSource source) => switch (source) {
  FanTempSource.cpuTctl => Metrics.cpuTctl,
  FanTempSource.gpuJunction => Metrics.gpuJunction,
  FanTempSource.gpuEdge => Metrics.gpuEdge,
  FanTempSource.boardSystem1 => Metrics.boardSystem1,
  FanTempSource.boardSystem2 => Metrics.boardSystem2,
  FanTempSource.boardPch => Metrics.boardPch,
  FanTempSource.boardCpuSocket => Metrics.boardCpuSocket,
  FanTempSource.boardVrm => Metrics.boardVrm,
  FanTempSource.boardPciex16 => Metrics.boardPciex16,
  FanTempSource.boardPciex4 => Metrics.boardPciex4,
};
