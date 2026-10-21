import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/monitoring/domain/gpu_fan.dart';

void main() {
  test('no reading is unknown', () {
    expect(gpuFanState(rpm: null, junction: 50), GpuFanState.unknown);
  });

  test('a turning fan is spinning, whatever the temperature', () {
    expect(gpuFanState(rpm: 1800, junction: 90), GpuFanState.spinning);
    expect(gpuFanState(rpm: 1800, junction: null), GpuFanState.spinning);
  });

  test('0 RPM with a cool GPU is zero-fan', () {
    expect(gpuFanState(rpm: 0, junction: 46), GpuFanState.zeroFan);
    expect(gpuFanState(rpm: 0, junction: null), GpuFanState.zeroFan);
  });

  test('0 RPM from the hot threshold on is a fault', () {
    expect(
      gpuFanState(rpm: 0, junction: gpuFanStoppedHotC - 0.1),
      GpuFanState.zeroFan,
    );
    expect(
      gpuFanState(rpm: 0, junction: gpuFanStoppedHotC),
      GpuFanState.stoppedHot,
    );
  });
}
