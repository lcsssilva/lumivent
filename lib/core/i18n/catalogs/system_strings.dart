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
