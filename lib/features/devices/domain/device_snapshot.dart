import 'device.dart';
import 'device_info.dart';

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
