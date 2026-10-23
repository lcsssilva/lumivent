/// Hub output. Implemented by the devices module AL V2 driver.
abstract interface class FanDriver {
  /// Sends duty (1–100) for [group]. `false` if the hub is inaccessible.
  Future<bool> setDuty(int group, int duty);

  /// Disables motherboard RPM sync for all 4 groups. The app controls the fans;
  /// otherwise (for example, if the vendor software left sync enabled on
  /// Windows), the hub would ignore duty. `false` if inaccessible.
  Future<bool> disableMotherboardSync();
}
