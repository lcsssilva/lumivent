import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/fans/application/fan_temp_metric.dart';
import 'package:lumivent/features/fans/domain/fan_curve.dart';
import 'package:lumivent/features/fans/domain/fan_group.dart';
import 'package:lumivent/features/fans/infrastructure/metrics_fan_temperatures.dart';
import 'package:lumivent/features/monitoring/monitoring.dart';

void main() {
  test('every fan temperature source maps to its monitoring metric', () {
    expect(
      {for (final s in FanTempSource.values) s: fanTempMetric(s)},
      {
        FanTempSource.cpuTctl: 'cpu.tctl',
        FanTempSource.gpuJunction: 'gpu.junction',
        FanTempSource.gpuEdge: 'gpu.edge',
        FanTempSource.boardSystem1: 'board.system1',
        FanTempSource.boardSystem2: 'board.system2',
        FanTempSource.boardPch: 'board.pch',
        FanTempSource.boardCpuSocket: 'board.cpu',
        FanTempSource.boardVrm: 'board.vrm',
        FanTempSource.boardPciex16: 'board.pciex16',
        FanTempSource.boardPciex4: 'board.pciex4',
      },
    );
  });

  test('board source metrics exist in the monitoring board list', () {
    final boardIds = {for (final m in Metrics.boardTemps) m.id};
    for (final s in FanTempSource.values.where((s) => s.isBoard)) {
      expect(boardIds, contains(fanTempMetric(s)));
    }
  });

  test('the engine reader returns the value of the mapped metric', () {
    final values = {
      for (final s in FanTempSource.values) fanTempMetric(s): s.index + 30.0,
    };
    final reader = MetricsFanTemperatures(
      () => SensorSample(DateTime(2026), values),
    );
    for (final s in FanTempSource.values) {
      expect(reader.read(s), s.index + 30.0);
    }
  });

  test('fan size reports its diameter', () {
    expect(FanSize.mm120.diameterMm, 120);
    expect(FanSize.mm140.diameterMm, 140);
  });
}
