import 'hardware_family_job.dart';

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
