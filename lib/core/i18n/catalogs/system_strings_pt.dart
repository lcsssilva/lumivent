import 'system_strings.dart';

class SystemStringsPt extends SystemStrings {
  const SystemStringsPt();

  @override
  String get permissionsAndSystem => 'Permissões e sistema';
  @override
  String get udevRules => 'Regras udev';
  @override
  String get boardSensors => 'Sensores da placa-mãe (it87)';
  @override
  String get memorySmbus => 'SMBus da memória';
  @override
  String get memoryTemperature => 'Temperatura da memória';
  @override
  String get nvmeSmartHelper => 'Helper NVMe SMART';
  @override
  String get hubRpmSync => 'Sync de RPM do hub';
  @override
  String get hubArgbSync => 'Sync ARGB e merge do hub';
  @override
  String get lightingLoop => 'Laço da iluminação';
  @override
  String udevInstalled(String file) => '$file instalada';
  @override
  String udevMissing(String file) => 'instale o pacote lumivent ($file)';
  @override
  String boardSensorsLoaded(String modules) => modules;
  @override
  String get boardSensorsMissing => 'módulo it87 não carregado';
  @override
  String memorySmbusOk(String bus) => bus;
  @override
  String get memorySmbusMissing =>
      'PIIX4 0x0B00 ausente (acpi_enforce_resources=lax)';
  @override
  String memoryTemperatureOk(String driver) => driver;
  @override
  String get memoryTemperatureMissing => 'driver spd5118 não carregado';
  @override
  String nvmeHelperOk(String path) => path;
  @override
  String nvmeHelperNoCaps(String path) => '$path não tem capabilities.';
  @override
  String get nvmeHelperMissing =>
      'Instale o pacote lumivent (helper em /usr/lib/lumivent).';
  @override
  String get hubRpmSyncPending => 'Esperando o primeiro ciclo das fans.';
  @override
  String get hubRpmSyncOk =>
      'Desligado pelo app nesta sessão (o software do fabricante pode tê-lo '
      'deixado ligado no Windows).';
  @override
  String get hubRpmSyncWarn =>
      'O hub ainda não aceitou o desligamento; as fans podem seguir a '
      'placa-mãe. O app tenta de novo a cada ciclo.';
  @override
  String get hubArgbSyncPending => 'Esperando a iluminação.';
  @override
  String get hubArgbSyncOk =>
      'Desligados na partida da iluminação (outros programas de RGB podem '
      'tê-los deixado ligados).';
  @override
  String get hubArgbSyncWarn => 'Hub AL V2 indisponível.';
  @override
  String get hubUnavailable => 'Hub AL V2 indisponível.';
  @override
  String get loopFamilyFans => 'fans';
  @override
  String get loopFamilyBoard => 'placa/gabinete';
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
      'Não foi possível atualizar a inicialização.\n'
      'Detalhes técnicos: $command: $stderr';
}
