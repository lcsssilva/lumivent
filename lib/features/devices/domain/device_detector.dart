import 'device.dart';

/// Detection port. The real implementation reads hardware (infrastructure);
/// tests use a fake one.
abstract interface class DeviceDetector {
  /// Cheap key (enumeration only) that changes when something is connected,
  /// or a competing program starts/stops.
  String presenceKey();

  /// Full scan, including identification reads.
  DeviceSnapshot scan();
  void dispose();
}
