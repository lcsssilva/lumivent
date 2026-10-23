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
