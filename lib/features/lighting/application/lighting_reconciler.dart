import 'dart:async';

/// Coalesces config updates and applies hardware changes family by family.
class LightingReconciler {
  bool _pending = false;

  void schedule(Future<void> Function() run) {
    if (_pending) return;
    _pending = true;
    unawaited(run());
  }

  Future<void> reconcile({
    required bool active,
    required bool hardwareResend,
    required void Function() forgetHardwareModes,
    required bool Function() fansReady,
    required Future<bool> Function() reconcileFans,
    required bool Function() boardReady,
    required Future<bool> Function() reconcileBoard,
    required bool Function() gpuReady,
    required Future<bool> Function() reconcileGpu,
    required bool Function() isStopped,
    required void Function() emitStatus,
    required void Function() syncTimer,
    required void Function() scheduleHardwareResend,
  }) async {
    _pending = false;
    if (!active) return;
    if (hardwareResend) forgetHardwareModes();
    var hardware = false;
    try {
      if (fansReady()) hardware = await reconcileFans() || hardware;
      if (isStopped()) return;
      if (boardReady()) hardware = await reconcileBoard() || hardware;
      if (isStopped()) return;
      if (gpuReady()) hardware = await reconcileGpu() || hardware;
    } finally {
      emitStatus();
      syncTimer();
    }
    if (hardware && !hardwareResend) scheduleHardwareResend();
  }
}
