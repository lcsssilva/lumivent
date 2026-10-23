import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/lighting/application/hardware/device_health_monitor.dart';
import 'package:lumivent/features/lighting/application/status/light_output_state.dart';
import 'package:lumivent/features/lighting/domain/light_device.dart';

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

  test('hasUnavailableFamilies tracks the hub, ITE and GPU', () {
    final health = DeviceHealthMonitor();
    expect(health.hasUnavailableFamilies, isTrue);

    health
      ..setReady(OutputFamily.fans, true)
      ..setReady(OutputFamily.ite, true);
    expect(health.hasUnavailableFamilies, isTrue);

    health.setReady(OutputFamily.gpu, true);
    expect(health.hasUnavailableFamilies, isFalse);

    health.markDown(
      OutputFamily.ite,
      DateTime(2026, 10, 21),
      const Duration(seconds: 5),
    );
    expect(health.boardReady, isFalse);
    expect(health.hasUnavailableFamilies, isTrue);
    expect(health.retryDue(), DateTime(2026, 10, 21, 0, 0, 5));
  });

  test('retryDue is null when up and lets the GPU wait for its backoff', () {
    final health = DeviceHealthMonitor();
    final at = DateTime(2026, 10, 21);
    for (final f in [OutputFamily.fans, OutputFamily.ite, OutputFamily.gpu]) {
      health.setReady(f, true);
    }
    expect(health.retryDue(), isNull);

    health
      ..setReady(OutputFamily.gpu, false)
      ..scheduleRetry(at, const Duration(seconds: 5))
      ..recordGpuInitFailure(
        at,
        retryEvery: const Duration(seconds: 30),
        retryMax: const Duration(minutes: 5),
      );
    expect(health.retryDue(), at.add(const Duration(seconds: 30)));
  });

  test('RAM sticks fail and recover individually', () {
    final health = DeviceHealthMonitor();
    final retryAt = DateTime(2026, 10, 21, 0, 0, 5);

    expect(health.isRamDown(LightDeviceId.ram1), isFalse);
    health.recordRamFailure(LightDeviceId.ram1, retryAt);
    expect(health.isRamDown(LightDeviceId.ram1), isTrue);
    expect(health.isRamDown(LightDeviceId.ram2), isFalse);
    expect(health.ramRetryAt(LightDeviceId.ram1), retryAt);

    expect(health.recordRamSuccess(LightDeviceId.ram2), isFalse);
    expect(health.recordRamSuccess(LightDeviceId.ram1), isTrue);
    expect(health.isRamDown(LightDeviceId.ram1), isFalse);
    expect(health.ramRetryAt(LightDeviceId.ram1), isNull);
    // A failed stick does not count as an unavailable family.
    health.recordRamFailure(LightDeviceId.ram2, retryAt);
    for (final f in [OutputFamily.fans, OutputFamily.ite, OutputFamily.gpu]) {
      health.setReady(f, true);
    }
    expect(health.hasUnavailableFamilies, isFalse);
  });

  test('the RAM off sequence marks both sticks and reset clears them', () {
    final health = DeviceHealthMonitor();
    health.setRamOff(ok: false);
    expect(health.isRamDown(LightDeviceId.ram1), isTrue);
    expect(health.isRamDown(LightDeviceId.ram2), isTrue);
    health.setRamOff(ok: true);
    expect(health.isRamDown(LightDeviceId.ram1), isFalse);

    health
      ..recordRamFailure(LightDeviceId.ram2, DateTime(2026))
      ..setReady(OutputFamily.fans, true)
      ..recordGpuInitFailure(
        DateTime(2026),
        retryEvery: const Duration(seconds: 5),
        retryMax: const Duration(minutes: 1),
      )
      ..reset();
    expect(health.isRamDown(LightDeviceId.ram2), isFalse);
    expect(health.ramRetryAt(LightDeviceId.ram2), isNull);
    expect(health.fansReady, isFalse);
    expect(health.gpuRetryAt, isNull);
  });
}
