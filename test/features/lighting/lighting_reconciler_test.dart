import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/lighting/application/hardware/lighting_reconciler.dart';
import 'package:lumivent/features/lighting/application/hardware/hardware_family_job.dart';
import 'package:lumivent/features/lighting/application/hardware/lighting_reconcile_job.dart';

void main() {
  test('reconciles families in order and schedules hardware resend', () async {
    final reconciler = LightingReconciler();
    final calls = <String>[];
    final status = <String>[];

    await reconciler.reconcile(
      LightingReconcileJob(
        active: true,
        hardwareResend: false,
        forgetHardwareModes: () => calls.add('forget'),
        families: [
          HardwareFamilyJob(
            ready: () => true,
            reconcile: () async {
              calls.add('fans');
              return true;
            },
          ),
          HardwareFamilyJob(
            ready: () => true,
            reconcile: () async {
              calls.add('board');
              return false;
            },
          ),
          HardwareFamilyJob(
            ready: () => true,
            reconcile: () async {
              calls.add('gpu');
              return false;
            },
          ),
        ],
        isStopped: () => false,
        emitStatus: () => status.add('status'),
        syncTimer: () => status.add('timer'),
        scheduleHardwareResend: () => calls.add('resend'),
      ),
    );

    expect(calls, ['fans', 'board', 'gpu', 'resend']);
    expect(status, ['status', 'timer']);
  });

  test('a stop after a family skips the remaining families', () async {
    final reconciler = LightingReconciler();
    final calls = <String>[];
    final status = <String>[];
    var stopped = false;

    await reconciler.reconcile(
      LightingReconcileJob(
        active: true,
        hardwareResend: false,
        forgetHardwareModes: () => calls.add('forget'),
        families: [
          HardwareFamilyJob(
            ready: () => true,
            reconcile: () async {
              calls.add('fans');
              stopped = true;
              return true;
            },
          ),
          HardwareFamilyJob(
            ready: () => true,
            reconcile: () async {
              calls.add('board');
              return false;
            },
          ),
        ],
        isStopped: () => stopped,
        emitStatus: () => status.add('status'),
        syncTimer: () => status.add('timer'),
        scheduleHardwareResend: () => calls.add('resend'),
      ),
    );

    expect(calls, ['fans']);
    expect(status, ['status', 'timer']);
  });

  test('an idle pass does not touch the hardware', () async {
    final reconciler = LightingReconciler();
    final calls = <String>[];

    await reconciler.reconcile(
      LightingReconcileJob(
        active: false,
        hardwareResend: true,
        forgetHardwareModes: () => calls.add('forget'),
        families: [
          HardwareFamilyJob(
            ready: () => true,
            reconcile: () async {
              calls.add('fans');
              return true;
            },
          ),
        ],
        isStopped: () => false,
        emitStatus: () => calls.add('status'),
        syncTimer: () => calls.add('timer'),
        scheduleHardwareResend: () => calls.add('resend'),
      ),
    );

    expect(calls, isEmpty);
  });
}
