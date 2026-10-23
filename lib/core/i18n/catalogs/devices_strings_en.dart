import 'devices_strings.dart';

class DevicesStringsEn extends DevicesStrings {
  const DevicesStringsEn();

  @override
  String get devices => 'Devices';
  @override
  String get devicesHeader => 'DEVICES';
  @override
  String get detectAgain => 'Detect again';
  @override
  String get detectingDevices => 'Detecting devices…';
  @override
  String get joinedBy => ', ';
  @override
  String conflicts(String programs, {required bool plural}) =>
      '$programs ${plural ? 'are running and' : 'is running and'} may compete '
      'for the same devices. Close ${plural ? 'them' : 'it'} before using '
      'lighting and fans.';
  @override
  String get alv2Fans => 'AL V2 fans';
  @override
  String get boardAndCase => 'Motherboard and case';
  @override
  String get graphicsCard => 'Graphics card';
  @override
  String get memoryModules => 'Memory modules';
  @override
  String memoryModule(int slot) => 'Memory module $slot';
  @override
  String get connected => 'Connected';
  @override
  String get notFound => 'Not found';
  @override
  String get noPermission => 'No permission';
  @override
  String get unavailable => 'Unavailable';
  @override
  String get blocked => 'Blocked';
  @override
  String get unsupported => 'Unsupported';
  @override
  String get error => 'Error';
  @override
  String get udevRulesHint =>
      'Install the lumivent package (udev rules) and reconnect the device or '
      'reboot.';
  @override
  String get fanUsbCableHint => 'Check the fan controller USB cable.';
  @override
  String get motherboardRgbHint =>
      'The motherboard RGB controller was not found on USB.';
  @override
  String get memoryBusHint =>
      'Requires acpi_enforce_resources=lax and the i2c-dev module (see the '
      'README; reboot).';
  @override
  String get gpuSsidHint =>
      'The app does not send effects until it confirms SSID 0x2429.';
  @override
  String get unsafeAddressHint =>
      'Address ignored for safety: it is not the memory LED controller.';
  @override
  String noResponse(String where) => '$where did not respond';
}
