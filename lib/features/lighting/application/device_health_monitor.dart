import '../domain/light_device.dart';
import 'lighting_messages.dart';

/// Readiness and retry state for the lighting output families.
///
/// The hub ([OutputFamily.fans]), the ITE controller ([OutputFamily.ite]) and
/// the GPU are ready or down as a whole; the RAM sticks fail one by one and
/// each retries on its own timer. The engine module decides when to act; this
/// class only records the state and answers when the next retry is due.
class DeviceHealthMonitor {
  bool _fansReady = false;
  bool _boardReady = false;
  bool _gpuReady = false;
  final _ramDown = <LightDeviceId>{};
  final _ramRetryAt = <LightDeviceId, DateTime>{};
  DateTime _nextRetry = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime? _gpuRetryAt;
  int _gpuInitFailures = 0;

  bool get fansReady => _fansReady;
  bool get boardReady => _boardReady;
  bool get gpuReady => _gpuReady;

  bool get hasUnavailableFamilies => !_fansReady || !_boardReady || !_gpuReady;

  /// When the GPU may be identified again; null when it is not in backoff.
  DateTime? get gpuRetryAt => _gpuRetryAt;

  /// Records the result of an init or off sequence for [family] (fans, ite or
  /// gpu).
  void setReady(OutputFamily family, bool ready) {
    switch (family) {
      case OutputFamily.fans:
        _fansReady = ready;
      case OutputFamily.ite:
        _boardReady = ready;
      case OutputFamily.gpu:
        _gpuReady = ready;
      case OutputFamily.ram:
        throw ArgumentError.value(
          family,
          'family',
          'RAM sticks fail individually; use recordRamFailure',
        );
    }
  }

  /// A write to [family] failed: it drops until the next init, and the
  /// hub/ITE retry [after] from [from].
  void markDown(OutputFamily family, DateTime from, Duration after) {
    setReady(family, false);
    scheduleRetry(from, after);
  }

  /// Delays the next hub/ITE retry to [after] from [from].
  void scheduleRetry(DateTime from, Duration after) {
    _nextRetry = from.add(after);
  }

  /// When the next retry of the families that are down is due, or null when
  /// every family is up. A GPU in backoff waits for its own time; the hub and
  /// ITE use the shared retry instant.
  DateTime? retryDue() {
    if (!hasUnavailableFamilies) return null;
    final due = [
      if (!_fansReady || !_boardReady) _nextRetry,
      if (!_gpuReady) _gpuRetryAt ?? _nextRetry,
    ];
    return due.reduce((a, b) => a.isBefore(b) ? a : b);
  }

  /// A failed GPU identification: the wait doubles from [retryEvery] up to
  /// [retryMax].
  void recordGpuInitFailure(
    DateTime at, {
    required Duration retryEvery,
    required Duration retryMax,
  }) {
    _gpuInitFailures++;
    final shift = (_gpuInitFailures - 1).clamp(0, 20);
    final wait = retryEvery * (1 << shift);
    _gpuRetryAt = at.add(wait > retryMax ? retryMax : wait);
  }

  void resetGpuBackoff() {
    _gpuInitFailures = 0;
    _gpuRetryAt = null;
  }

  bool isRamDown(LightDeviceId id) => _ramDown.contains(id);

  /// When stick [id] may be written again, or null when it is not waiting.
  DateTime? ramRetryAt(LightDeviceId id) => _ramRetryAt[id];

  /// Stick [id] failed a write; it is skipped until [retryAt].
  void recordRamFailure(LightDeviceId id, DateTime retryAt) {
    _ramRetryAt[id] = retryAt;
    _ramDown.add(id);
  }

  /// Stick [id] wrote successfully. Returns whether it had been down.
  bool recordRamSuccess(LightDeviceId id) {
    _ramRetryAt.remove(id);
    return _ramDown.remove(id);
  }

  /// The result of the RAM off sequence: both sticks down or both up.
  void setRamOff({required bool ok}) {
    _ramDown
      ..clear()
      ..addAll(ok ? const [] : [LightDeviceId.ram1, LightDeviceId.ram2]);
  }

  /// Forgets every failure (re-init): all families must be initialized again
  /// and the GPU is identified right away.
  void reset() {
    _fansReady = false;
    _boardReady = false;
    _gpuReady = false;
    _ramDown.clear();
    _ramRetryAt.clear();
    resetGpuBackoff();
  }
}
