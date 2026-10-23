import 'devices_strings.dart';

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
