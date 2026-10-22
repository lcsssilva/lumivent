import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/lighting/application/device_health_monitor.dart';

void main() {
  test('GPU initialization retry backs off and resets after recovery', () {
    final health = DeviceHealthMonitor();
    final at = DateTime(2026, 10, 21);

    health.recordGpuInitFailure(
      at,
      retryEvery: const Duration(seconds: 5),
      retryMax: const Duration(seconds: 12),
    );
    expect(health.gpuRetryAt, at.add(const Duration(seconds: 5)));

    health.recordGpuInitFailure(
      at,
      retryEvery: const Duration(seconds: 5),
      retryMax: const Duration(seconds: 12),
    );
    expect(health.gpuRetryAt, at.add(const Duration(seconds: 10)));

    health.recordGpuInitFailure(
      at,
      retryEvery: const Duration(seconds: 5),
      retryMax: const Duration(seconds: 12),
    );
    expect(health.gpuRetryAt, at.add(const Duration(seconds: 12)));

    health.resetGpuBackoff();
    expect(health.gpuRetryAt, isNull);
  });
}
