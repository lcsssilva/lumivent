/// An hwmon chip (`/sys/class/hwmon/hwmonN`).
class Hwmon {
  Hwmon(this.name, this.path, this.device);
  final String name;
  final String path;

  /// Real device path (identifies the NVMe drive, memory module, etc.).
  final String device;
}
