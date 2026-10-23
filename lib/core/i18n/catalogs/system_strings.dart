/// System page: environment diagnostics, runtime checks, and autostart errors.
abstract class SystemStrings {
  const SystemStrings();

  String get permissionsAndSystem;

  // Diagnostic labels.
  String get udevRules;
  String get boardSensors;
  String get memorySmbus;
  String get memoryTemperature;
  String get nvmeSmartHelper;
  String get hubRpmSync;
  String get hubArgbSync;
  String get lightingLoop;

  // Environment details.
  String udevInstalled(String file);
  String udevMissing(String file);
  String boardSensorsLoaded(String modules);
  String get boardSensorsMissing;
  String memorySmbusOk(String bus);
  String get memorySmbusMissing;
  String memoryTemperatureOk(String driver);
  String get memoryTemperatureMissing;
  String nvmeHelperOk(String path);
  String nvmeHelperNoCaps(String path);
  String get nvmeHelperMissing;

  // Runtime check details.
  String get hubRpmSyncPending;
  String get hubRpmSyncOk;
  String get hubRpmSyncWarn;
  String get hubArgbSyncPending;
  String get hubArgbSyncOk;
  String get hubArgbSyncWarn;
  String get hubUnavailable;
  String get loopFamilyFans;
  String get loopFamilyBoard;
  String get loopFamilyRam;
  String get loopFamilyGpu;
  String loopFps(String fps);
  String loopFpsMs(String fps, String ms);
  String loopValue(String family, String value);

  // Autostart.
  String autostartFailed(String command, String stderr);
}
