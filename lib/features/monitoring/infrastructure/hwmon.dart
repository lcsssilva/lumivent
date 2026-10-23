part of 'sysfs_sensor_source.dart';

/// An hwmon chip (`/sys/class/hwmon/hwmonN`).
class _Hwmon {
  _Hwmon(this.name, this.path, this.device);
  final String name;
  final String path;

  /// Real device path (identifies the NVMe drive, memory module, etc.).
  final String device;
}
