// Devices module domain: what the engine detects and sends to the UI.
//
// Pure Dart (no Flutter, IO, or FFI), safe to send between isolates.
// The fan and lighting drivers (phases 3 and 4) build on this model; it only
// contains each device's identity and access state.

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

/// Immutable device snapshot, safe to send between isolates.
class DeviceInfo {
  const DeviceInfo({
    required this.id,
    required this.kind,
    required this.name,
    required this.model,
    required this.status,
    this.detail,
    this.hint,
  });

  /// Stable between runs (used by configuration in future phases).
  final String id;
  final DeviceKind kind;
  final String name;
  final String model;
  final DeviceStatus status;

  /// Firmware, node path, or error message.
  final String? detail;

  /// What the user can do to resolve an unhealthy status.
  final String? hint;

  @override
  bool operator ==(Object other) =>
      other is DeviceInfo &&
      other.id == id &&
      other.kind == kind &&
      other.name == name &&
      other.model == model &&
      other.status == status &&
      other.detail == detail &&
      other.hint == hint;

  @override
  int get hashCode => Object.hash(id, kind, name, model, status, detail, hint);

  @override
  String toString() =>
      '$id: ${status.name}${detail == null ? '' : ' ($detail)'}';
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
