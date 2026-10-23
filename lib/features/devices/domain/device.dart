// Devices module domain: what the engine detects and sends to the UI.
//
// Pure Dart (no Flutter, IO, or FFI), safe to send between isolates.
// The fan and lighting drivers (phases 3 and 4) build on this model; it only
// contains each device's identity and access state.

import 'device_info.dart';

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
