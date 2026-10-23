import 'monitoring_strings.dart';

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
