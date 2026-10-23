import 'nvme_smart_log.dart';
import 'ssd_smart_error.dart';

/// An NVMe SSD: sysfs identification (no privileges) + helper SMART data.
class SsdInfo {
  const SsdInfo({
    required this.controller,
    required this.model,
    required this.serial,
    required this.firmware,
    this.capacityBytes,
    this.smart,
    this.smartError,
  });

  /// `nvme0`, `nvme1`…
  final String controller;
  final String model;
  final String serial;
  final String firmware;
  final int? capacityBytes;

  /// `null` if the helper is not installed or fails ([smartError]).
  final NvmeSmartLog? smart;
  final SsdSmartError? smartError;
}
