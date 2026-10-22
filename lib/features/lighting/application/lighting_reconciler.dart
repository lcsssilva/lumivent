import 'dart:async';

/// One hardware family in a reconciliation pass: whether it is up and how to
/// apply the pending config to it.
class HardwareFamilyJob {
  const HardwareFamilyJob({required this.ready, required this.reconcile});

  /// Skips the family when it is not up; a failed family is retried later.
  final bool Function() ready;

  /// Applies the config and reports whether anything was written.
  final Future<bool> Function() reconcile;
}

/// One reconciliation pass: the coalesced config update and the families that
/// may need to be written, in order.
class LightingReconcileJob {
  const LightingReconcileJob({
    required this.active,
    required this.hardwareResend,
    required this.forgetHardwareModes,
    required this.families,
    required this.isStopped,
    required this.emitStatus,
    required this.syncTimer,
    required this.scheduleHardwareResend,
  });

  /// Whether lighting is driving the hardware; an idle pass does nothing.
  final bool active;

  /// Writes the modes again even though the config did not change.
  final bool hardwareResend;

  final void Function() forgetHardwareModes;

  /// Families in write order (fans, board, GPU).
  final List<HardwareFamilyJob> families;

  final bool Function() isStopped;
  final void Function() emitStatus;
  final void Function() syncTimer;
  final void Function() scheduleHardwareResend;
}

/// Coalesces config updates and applies hardware changes family by family.
class LightingReconciler {
  bool _pending = false;

  void schedule(Future<void> Function() run) {
    if (_pending) return;
    _pending = true;
    unawaited(run());
  }

  Future<void> reconcile(LightingReconcileJob job) async {
    _pending = false;
    if (!job.active) return;
    if (job.hardwareResend) job.forgetHardwareModes();
    var hardware = false;
    try {
      for (var i = 0; i < job.families.length; i++) {
        if (i > 0 && job.isStopped()) return;
        final family = job.families[i];
        if (family.ready()) hardware = await family.reconcile() || hardware;
      }
    } finally {
      job.emitStatus();
      job.syncTimer();
    }
    if (hardware && !job.hardwareResend) job.scheduleHardwareResend();
  }
}
