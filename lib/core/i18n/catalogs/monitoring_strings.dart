/// Monitoring page: sensor cards, numbers, and the SSD/SMART tool.
abstract class MonitoringStrings {
  const MonitoringStrings();

  // Cards.
  String get gpu;
  String get memory;
  String get motherboard;
  String get alv2Fans;

  // GPU caption and fan states.
  String get junction;
  String get fanStoppedZeroFan;
  String get fanStoppedHot;

  // Stat labels.
  String get averageClock;
  String get usage;
  String get fan;
  String get edge;
  String get memoryLabel;
  String get clock;
  String get power;
  String get vram;
  String memoryStick(int slot);

  // Sections.
  String get temperatures;
  String get fansAndPump;
  String get noBoardSensors;
  String get noFanConnectors;
  String get noAlv2Reading;
  String memoryOf(String total, int percent);

  // History footer.
  String get lastFiveMinutes;
  String lastFiveMinutesRange(String min, String max);

  // Metrics shown by the motherboard card.
  String metricLabel(String id, String fallback);

  // SSD section.
  String get storage;
  String ssdRefreshedAt(String time);
  String get readingSsds;
  String get noNvme;
  String get smartUnavailable;
  String get noSmart;
  String get temperature;
  String get powerOnHours;
  String get written;
  String get read;
  String get powerCycles;
  String get unsafeShutdowns;
  String get mediaErrors;
  String get availableSpare;
  String get criticalWarning;
  String get remainingLife;
  String get smartDialogSubtitle;

  // SMART detail rows.
  String get compositeTemperature;
  String get spareThreshold;
  String get percentageUsed;
  String get dataUnitsRead;
  String get dataUnitsWritten;
  String get hostReadCommands;
  String get hostWriteCommands;
  String get controllerBusy;
  String get mediaErrorsAndIntegrity;
  String get errorLogEntries;
  String get warningTempTime;
  String get criticalTempTime;
  String sensorTemperature(int index);

  // SMART warnings and health.
  String smartWarning(int bit);
  String get healthGood;
  String get healthWarning;
  String get healthBad;

  // Reasons SMART is unavailable.
  String get ssdHelperMissing;
  String ssdHelperFailed(String error);
  String ssdHelperExit(int code, String stderr);
  String get ssdInvalidResponse;
}

class MonitoringStringsEn extends MonitoringStrings {
  const MonitoringStringsEn();

  @override
  String get gpu => 'GPU';
  @override
  String get memory => 'Memory';
  @override
  String get motherboard => 'Motherboard';
  @override
  String get alv2Fans => 'AL V2 fans';
  @override
  String get junction => 'junction';
  @override
  String get fanStoppedZeroFan => 'stopped (zero-fan)';
  @override
  String get fanStoppedHot => 'stopped (hot GPU!)';
  @override
  String get averageClock => 'Average clock';
  @override
  String get usage => 'Usage';
  @override
  String get fan => 'Fan';
  @override
  String get edge => 'Edge';
  @override
  String get memoryLabel => 'Memory';
  @override
  String get clock => 'Clock';
  @override
  String get power => 'Power';
  @override
  String get vram => 'VRAM';
  @override
  String memoryStick(int slot) => 'Stick $slot';
  @override
  String get temperatures => 'Temperatures';
  @override
  String get fansAndPump => 'Fans and pump (read-only)';
  @override
  String get noBoardSensors =>
      'No motherboard sensors: the it87 module is not loaded (see Settings).';
  @override
  String get noFanConnectors => 'No connector with RPM.';
  @override
  String get noAlv2Reading =>
      'No reading from the AL V2 hub (see Devices in Settings).';
  @override
  String memoryOf(String total, int percent) => 'of $total · $percent %';
  @override
  String get lastFiveMinutes => 'last 5 min';
  @override
  String lastFiveMinutesRange(String min, String max) =>
      'last 5 min · min $min · max $max';
  @override
  String metricLabel(String id, String fallback) => switch (id) {
    'board.cpu' => 'CPU (socket)',
    'board.fan.cpu' => 'Pump (CPU_FAN)',
    _ => fallback,
  };
  @override
  String get storage => 'Storage';
  @override
  String ssdRefreshedAt(String time) => 'updates every minute · read at $time';
  @override
  String get readingSsds => 'Reading SSDs…';
  @override
  String get noNvme => 'No NVMe SSD found.';
  @override
  String get smartUnavailable =>
      'SMART unavailable: remaining life, TBW, and power-on hours are not '
      'available.';
  @override
  String get noSmart => 'No SMART';
  @override
  String get temperature => 'Temperature';
  @override
  String get powerOnHours => 'Power-on hours';
  @override
  String get written => 'Written';
  @override
  String get read => 'Read';
  @override
  String get powerCycles => 'Power cycles';
  @override
  String get unsafeShutdowns => 'Unsafe shutdowns';
  @override
  String get mediaErrors => 'Media errors';
  @override
  String get availableSpare => 'Available spare';
  @override
  String get criticalWarning => 'Critical warning';
  @override
  String get remainingLife => 'Remaining life';
  @override
  String get smartDialogSubtitle => 'SMART/Health (log 02h)';
  @override
  String get compositeTemperature => 'Composite temperature';
  @override
  String get spareThreshold => 'Spare threshold';
  @override
  String get percentageUsed => 'Percentage used';
  @override
  String get dataUnitsRead => 'Data units read';
  @override
  String get dataUnitsWritten => 'Data units written';
  @override
  String get hostReadCommands => 'Host read commands';
  @override
  String get hostWriteCommands => 'Host write commands';
  @override
  String get controllerBusy => 'Controller busy time';
  @override
  String get mediaErrorsAndIntegrity => 'Media and integrity errors';
  @override
  String get errorLogEntries => 'Error log entries';
  @override
  String get warningTempTime => 'Time above warning temperature';
  @override
  String get criticalTempTime => 'Time above critical temperature';
  @override
  String sensorTemperature(int index) => 'Temperature sensor $index';
  @override
  String smartWarning(int bit) => switch (bit) {
    0 => 'spare below threshold',
    1 => 'temperature out of range',
    2 => 'reliability degraded',
    3 => 'media read-only',
    4 => 'volatile memory backup failed',
    5 => 'PMR read-only',
    _ => 'warning $bit',
  };
  @override
  String get healthGood => 'Good';
  @override
  String get healthWarning => 'Warning';
  @override
  String get healthBad => 'Bad';
  @override
  String get ssdHelperMissing =>
      'Install the lumivent package (helper in /usr/lib/lumivent).';
  @override
  String ssdHelperFailed(String error) => 'failed to run the helper: $error';
  @override
  String ssdHelperExit(int code, String stderr) =>
      'the helper exited with $code: $stderr';
  @override
  String get ssdInvalidResponse => 'invalid response from the helper';
}

class MonitoringStringsPt extends MonitoringStrings {
  const MonitoringStringsPt();

  @override
  String get gpu => 'GPU';
  @override
  String get memory => 'Memória';
  @override
  String get motherboard => 'Placa-mãe';
  @override
  String get alv2Fans => 'Fans AL V2';
  @override
  String get junction => 'junction';
  @override
  String get fanStoppedZeroFan => 'parado (zero-fan)';
  @override
  String get fanStoppedHot => 'parado (GPU quente!)';
  @override
  String get averageClock => 'Clock médio';
  @override
  String get usage => 'Uso';
  @override
  String get fan => 'Fan';
  @override
  String get edge => 'Edge';
  @override
  String get memoryLabel => 'Memória';
  @override
  String get clock => 'Clock';
  @override
  String get power => 'Potência';
  @override
  String get vram => 'VRAM';
  @override
  String memoryStick(int slot) => 'Pente $slot';
  @override
  String get temperatures => 'Temperaturas';
  @override
  String get fansAndPump => 'Fans e bomba (somente leitura)';
  @override
  String get noBoardSensors =>
      'Sem sensores da placa-mãe: o módulo it87 não está carregado (veja '
      'Configurações).';
  @override
  String get noFanConnectors => 'Nenhum conector com RPM.';
  @override
  String get noAlv2Reading =>
      'Sem leitura do hub AL V2 (veja Dispositivos em Configurações).';
  @override
  String memoryOf(String total, int percent) => 'de $total · $percent %';
  @override
  String get lastFiveMinutes => 'últimos 5 min';
  @override
  String lastFiveMinutesRange(String min, String max) =>
      'últimos 5 min · mín $min · máx $max';
  @override
  String metricLabel(String id, String fallback) => switch (id) {
    'board.cpu' => 'CPU (soquete)',
    'board.fan.cpu' => 'Bomba (CPU_FAN)',
    _ => fallback,
  };
  @override
  String get storage => 'Armazenamento';
  @override
  String ssdRefreshedAt(String time) =>
      'atualiza a cada minuto · lido às $time';
  @override
  String get readingSsds => 'Lendo SSDs…';
  @override
  String get noNvme => 'Nenhum SSD NVMe encontrado.';
  @override
  String get smartUnavailable =>
      'SMART indisponível: vida restante, TBW e horas ligado não estão '
      'disponíveis.';
  @override
  String get noSmart => 'Sem SMART';
  @override
  String get temperature => 'Temperatura';
  @override
  String get powerOnHours => 'Horas ligado';
  @override
  String get written => 'Escritos';
  @override
  String get read => 'Lidos';
  @override
  String get powerCycles => 'Ciclos de energia';
  @override
  String get unsafeShutdowns => 'Desligamentos inseguros';
  @override
  String get mediaErrors => 'Erros de mídia';
  @override
  String get availableSpare => 'Reserva disponível';
  @override
  String get criticalWarning => 'Alerta crítico';
  @override
  String get remainingLife => 'Vida restante';
  @override
  String get smartDialogSubtitle => 'SMART/Health (log 02h)';
  @override
  String get compositeTemperature => 'Temperatura composta';
  @override
  String get spareThreshold => 'Limite da reserva';
  @override
  String get percentageUsed => 'Percentual usado';
  @override
  String get dataUnitsRead => 'Data units lidas';
  @override
  String get dataUnitsWritten => 'Data units escritas';
  @override
  String get hostReadCommands => 'Comandos de leitura';
  @override
  String get hostWriteCommands => 'Comandos de escrita';
  @override
  String get controllerBusy => 'Tempo ocupado do controlador';
  @override
  String get mediaErrorsAndIntegrity => 'Erros de mídia e integridade';
  @override
  String get errorLogEntries => 'Entradas no log de erros';
  @override
  String get warningTempTime => 'Tempo acima da temperatura de alerta';
  @override
  String get criticalTempTime => 'Tempo acima da temperatura crítica';
  @override
  String sensorTemperature(int index) => 'Sensor de temperatura $index';
  @override
  String smartWarning(int bit) => switch (bit) {
    0 => 'reserva abaixo do limite',
    1 => 'temperatura fora da faixa',
    2 => 'confiabilidade degradada',
    3 => 'mídia somente leitura',
    4 => 'backup da memória volátil falhou',
    5 => 'PMR somente leitura',
    _ => 'aviso $bit',
  };
  @override
  String get healthGood => 'Boa';
  @override
  String get healthWarning => 'Atenção';
  @override
  String get healthBad => 'Ruim';
  @override
  String get ssdHelperMissing =>
      'Instale o pacote lumivent (helper em /usr/lib/lumivent).';
  @override
  String ssdHelperFailed(String error) => 'falha ao executar o helper: $error';
  @override
  String ssdHelperExit(int code, String stderr) =>
      'o helper saiu com $code: $stderr';
  @override
  String get ssdInvalidResponse => 'resposta inválida do helper';
}
