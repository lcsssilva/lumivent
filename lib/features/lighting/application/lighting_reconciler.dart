import 'dart:async';

import 'lighting_reconcile_job.dart';

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
