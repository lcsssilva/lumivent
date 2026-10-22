import '../domain/light_device.dart';

/// Readiness and retry state for the lighting output families.
class DeviceHealthMonitor {
  bool fansReady = false;
  bool boardReady = false;
  bool gpuReady = false;
  final ramDown = <LightDeviceId>{};
  final ramRetryAt = <LightDeviceId, DateTime>{};
  DateTime nextRetry = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime? gpuRetryAt;
  int _gpuInitFailures = 0;

  bool get hasUnavailableFamilies => !fansReady || !boardReady || !gpuReady;

  void recordGpuInitFailure(
    DateTime at, {
    required Duration retryEvery,
    required Duration retryMax,
  }) {
    _gpuInitFailures++;
    final shift = (_gpuInitFailures - 1).clamp(0, 20);
    final wait = retryEvery * (1 << shift);
    gpuRetryAt = at.add(wait > retryMax ? retryMax : wait);
  }

  void resetGpuBackoff() {
    _gpuInitFailures = 0;
    gpuRetryAt = null;
  }
}
