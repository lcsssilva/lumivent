import 'monitoring_strings.dart';

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
