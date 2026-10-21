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

class DevicesStringsPt extends DevicesStrings {
  const DevicesStringsPt();

  @override
  String get devices => 'Dispositivos';
  @override
  String get devicesHeader => 'DISPOSITIVOS';
  @override
  String get detectAgain => 'Detectar novamente';
  @override
  String get detectingDevices => 'Detectando dispositivos…';
  @override
  String get joinedBy => ', ';
  @override
  String conflicts(String programs, {required bool plural}) =>
      '$programs ${plural ? 'estão rodando e' : 'está rodando e'} podem disputar '
      'os mesmos dispositivos. Feche-${plural ? 'os' : 'o'} antes de usar '
      'iluminação e fans.';
  @override
  String get alv2Fans => 'Fans AL V2';
  @override
  String get boardAndCase => 'Placa-mãe e gabinete';
  @override
  String get graphicsCard => 'Placa de vídeo';
  @override
  String get memoryModules => 'Módulos de memória';
  @override
  String memoryModule(int slot) => 'Módulo de memória $slot';
  @override
  String get connected => 'Conectado';
  @override
  String get notFound => 'Não encontrado';
  @override
  String get noPermission => 'Sem permissão';
  @override
  String get unavailable => 'Indisponível';
  @override
  String get blocked => 'Bloqueado';
  @override
  String get unsupported => 'Sem suporte';
  @override
  String get error => 'Erro';
  @override
  String get udevRulesHint =>
      'Instale o pacote lumivent (regras udev) e reconecte o dispositivo ou '
      'reinicie.';
  @override
  String get fanUsbCableHint => 'Confira o cabo USB do controlador das fans.';
  @override
  String get motherboardRgbHint =>
      'O controlador RGB da placa-mãe não foi encontrado no USB.';
  @override
  String get memoryBusHint =>
      'Requer acpi_enforce_resources=lax e o módulo i2c-dev (veja o README; '
      'reinicie).';
  @override
  String get gpuSsidHint =>
      'O app não envia efeitos sem confirmar o SSID 0x2429.';
  @override
  String get unsafeAddressHint =>
      'Endereço ignorado por segurança: não é o LED da memória.';
  @override
  String noResponse(String where) => '$where não respondeu';
}
