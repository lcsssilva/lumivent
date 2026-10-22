// Devices module domain: what the engine detects and sends to the UI.
//
// Pure Dart (no Flutter, IO, or FFI), safe to send between isolates.
// The fan and lighting drivers (phases 3 and 4) build on this model; it only
// contains each device's identity and access state.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'device.freezed.dart';

enum DeviceStatus {
  /// Found and responding.
  ok,

  /// Not connected (or not exposed by the kernel).
  missing,

  /// Exists, but the user has no access (missing udev rule).
  noPermission,

  /// The required bus/driver is not active (for example, PIIX4 without
  /// `acpi_enforce_resources=lax`).
  unavailable,

  /// Found, but a safety check prevents access.
  blocked,

  /// No driver yet (for example, GPU RGB until phase 7).
  unsupported,

  /// Failed in some other way; see [DeviceInfo.detail].
  error,
}

enum DeviceKind { fans, motherboard, memory, gpu }

/// Generic device name. Hardware models and user-chosen names stay as data.
enum DeviceLabel {
  alv2Fans,
  boardAndCase,
  memoryModules,
  memoryModule,
  graphicsCard,
}

/// What the user can do about an unhealthy status. The presentation composes
/// the sentence; the engine never generates UI text (plan D5).
enum DeviceIssue {
  udevRules,
  fanUsbCable,
  motherboardRgb,
  memoryBus,
  gpuSsid,
  unsafeAddress,
  noResponse,
}

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

/// Result of a full scan.
class DeviceSnapshot {
  const DeviceSnapshot({
    required this.devices,
    required this.conflicts,
    required this.scannedAt,
  });

  final List<DeviceInfo> devices;

  /// Running programs that compete for the same devices (OpenRGB, etc.).
  final List<String> conflicts;
  final DateTime scannedAt;

  Iterable<DeviceInfo> ofKind(DeviceKind kind) =>
      devices.where((d) => d.kind == kind);
}
