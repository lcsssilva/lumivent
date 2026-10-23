import 'package:lumivent/features/devices/devices.dart';

class FakeDetector implements DeviceDetector {
  String key = 'a';
  int scans = 0;
  bool disposed = false;

  @override
  String presenceKey() => key;

  @override
  DeviceSnapshot scan() {
    scans++;
    return DeviceSnapshot(
      devices: const [],
      conflicts: const [],
      scannedAt: DateTime(2026),
    );
  }

  @override
  void dispose() => disposed = true;
}
