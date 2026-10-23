import 'light_output_state.dart';

/// Estimates each output's send latency and the phase lead used for composing.
class LightingLatencyModel {
  static const alpha = 0.25;
  static const minLatencyMs = 0.0;
  static const maxLatencyMs = 150.0;

  /// Delay of the AL V2 firmware between receiving a canvas frame and showing
  /// it. Measured on hardware (2026-10-19, `tool/hw_test_fase4.dart sync`):
  /// with the fans streamed first, the case/board/RAM had to be sent ~150 ms
  /// after the fan send completed for both to change at the same instant.
  static const fanDisplayLatencyMs = 150.0;

  final _latencyMs = <OutputFamily, double>{
    OutputFamily.fans: 45,
    OutputFamily.ite: 1,
    OutputFamily.ram: 10,
    OutputFamily.gpu: 125,
  };

  Duration latencyOf(OutputFamily family) =>
      Duration(microseconds: (_latencyMs[family]! * 1000).round());

  void observe(OutputFamily family, Duration took) {
    final ms = took.inMicroseconds / 1000;
    final next = _latencyMs[family]! + alpha * (ms - _latencyMs[family]!);
    _latencyMs[family] = next.clamp(minLatencyMs, maxLatencyMs);
  }

  double leadSeconds(OutputFamily family, Duration gpuFrameGap) {
    final ms = _latencyMs[family]!;
    if (family == OutputFamily.fans) {
      return (ms + fanDisplayLatencyMs) / 1000;
    }
    if (family == OutputFamily.gpu) {
      return (ms - gpuFrameGap.inMilliseconds).clamp(0, 50) / 1000;
    }
    return ms / 1000;
  }
}
