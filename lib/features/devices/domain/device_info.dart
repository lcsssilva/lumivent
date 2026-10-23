import 'package:freezed_annotation/freezed_annotation.dart';

import 'device.dart';

part 'device_info.freezed.dart';

/// Immutable device snapshot, safe to send between isolates.
@freezed
abstract class DeviceInfo with _$DeviceInfo {
  const factory DeviceInfo({
    /// Stable between runs (used by configuration in future phases).
    required String id,
    required DeviceKind kind,
    required DeviceLabel label,

    /// Memory slot for [DeviceLabel.memoryModule] (1-based).
    int? slot,
    required String model,
    required DeviceStatus status,

    /// Firmware, node path, or a neutral technical error.
    String? detail,

    /// Actionable issue and its data (for example the bus that did not
    /// respond).
    DeviceIssue? issue,
    String? issueArg,
  }) = _DeviceInfo;
}
