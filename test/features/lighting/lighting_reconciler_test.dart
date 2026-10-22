import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/lighting/application/lighting_reconciler.dart';

void main() {
  test('reconciles families in order and schedules hardware resend', () async {
    final reconciler = LightingReconciler();
    final calls = <String>[];
    final status = <String>[];

    await reconciler.reconcile(
      active: true,
      hardwareResend: false,
      forgetHardwareModes: () => calls.add('forget'),
      fansReady: () => true,
      reconcileFans: () async {
        calls.add('fans');
        return true;
      },
      boardReady: () => true,
      reconcileBoard: () async {
        calls.add('board');
        return false;
      },
      gpuReady: () => true,
      reconcileGpu: () async {
        calls.add('gpu');
        return false;
      },
      isStopped: () => false,
      emitStatus: () => status.add('status'),
      syncTimer: () => status.add('timer'),
      scheduleHardwareResend: () => calls.add('resend'),
    );

    expect(calls, ['fans', 'board', 'gpu', 'resend']);
    expect(status, ['status', 'timer']);
  });
}
