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
