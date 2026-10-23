/// Device list: statuses, generic device names, hints, and conflict banners.
abstract class DevicesStrings {
  const DevicesStrings();

  String get devices;
  String get devicesHeader;
  String get detectAgain;
  String get detectingDevices;
  String get joinedBy;

  /// Banner when one or more competing programs are running.
  String conflicts(String programs, {required bool plural});

  // Generic device names. Hardware models and user-chosen names are not
  // translated (plan D10).
  String get alv2Fans;
  String get boardAndCase;
  String get graphicsCard;
  String get memoryModules;
  String memoryModule(int slot);

  // Status labels.
  String get connected;
  String get notFound;
  String get noPermission;
  String get unavailable;
  String get blocked;
  String get unsupported;
  String get error;

  // Hints (what the user can do about an unhealthy status).
  String get udevRulesHint;
  String get fanUsbCableHint;
  String get motherboardRgbHint;
  String get memoryBusHint;
  String get gpuSsidHint;
  String get unsafeAddressHint;
  String noResponse(String where);
}
