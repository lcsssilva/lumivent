import 'system_strings.dart';

class SystemStringsEn extends SystemStrings {
  const SystemStringsEn();

  @override
  String get permissionsAndSystem => 'Permissions and system';
  @override
  String get udevRules => 'udev rules';
  @override
  String get boardSensors => 'Motherboard sensors (it87)';
  @override
  String get memorySmbus => 'Memory SMBus';
  @override
  String get memoryTemperature => 'Memory temperature';
  @override
  String get nvmeSmartHelper => 'NVMe SMART helper';
  @override
  String get hubRpmSync => 'Hub RPM sync';
  @override
  String get hubArgbSync => 'Hub ARGB sync and merge';
  @override
  String get lightingLoop => 'Lighting loop';
  @override
  String udevInstalled(String file) => '$file installed';
  @override
  String udevMissing(String file) => 'install the lumivent package ($file)';
  @override
  String boardSensorsLoaded(String modules) => modules;
  @override
  String get boardSensorsMissing => 'it87 module not loaded';
  @override
  String memorySmbusOk(String bus) => bus;
  @override
  String get memorySmbusMissing =>
      'PIIX4 0x0B00 missing (acpi_enforce_resources=lax)';
  @override
  String memoryTemperatureOk(String driver) => driver;
  @override
  String get memoryTemperatureMissing => 'spd5118 driver not loaded';
  @override
  String nvmeHelperOk(String path) => path;
  @override
  String nvmeHelperNoCaps(String path) => '$path has no capabilities.';
  @override
  String get nvmeHelperMissing =>
      'Install the lumivent package (helper in /usr/lib/lumivent).';
  @override
  String get hubRpmSyncPending => 'Waiting for the first fan cycle.';
  @override
  String get hubRpmSyncOk =>
      'Turned off by the app in this session (the vendor software may have '
      'left it on in Windows).';
  @override
  String get hubRpmSyncWarn =>
      'The hub has not accepted the shutdown yet; the fans may follow the '
      'motherboard. The app tries again every cycle.';
  @override
  String get hubArgbSyncPending => 'Waiting for lighting.';
  @override
  String get hubArgbSyncOk =>
      'Turned off when lighting started (other RGB programs may have left '
      'them on).';
  @override
  String get hubArgbSyncWarn => 'AL V2 hub unavailable.';
  @override
  String get hubUnavailable => 'AL V2 hub unavailable.';
  @override
  String get loopFamilyFans => 'fans';
  @override
  String get loopFamilyBoard => 'board/case';
  @override
  String get loopFamilyRam => 'RAM';
  @override
  String get loopFamilyGpu => 'GPU';
  @override
  String loopFps(String fps) => '$fps fps';
  @override
  String loopFpsMs(String fps, String ms) => '$fps fps, $ms ms';
  @override
  String loopValue(String family, String value) => '$family $value';
  @override
  String autostartFailed(String command, String stderr) =>
      'Could not update the startup setting.\n'
      'Technical details: $command: $stderr';
}
