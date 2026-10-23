import 'ssd.dart';

/// Fields of the log SMART/Health (NVMe, Get Log Page 02h).
class NvmeSmartLog {
  const NvmeSmartLog({
    required this.criticalWarning,
    required this.compositeKelvin,
    required this.availableSpare,
    required this.availableSpareThreshold,
    required this.percentageUsed,
    required this.dataUnitsRead,
    required this.dataUnitsWritten,
    required this.hostReadCommands,
    required this.hostWriteCommands,
    required this.controllerBusyMinutes,
    required this.powerCycles,
    required this.powerOnHours,
    required this.unsafeShutdowns,
    required this.mediaErrors,
    required this.errorLogEntries,
    required this.warningTempMinutes,
    required this.criticalTempMinutes,
    required this.sensorsKelvin,
  });

  /// One "data unit" = 1000 sectors of 512 bytes.
  static const dataUnitBytes = 512000;

  final int criticalWarning;
  final int compositeKelvin;
  final int availableSpare;
  final int availableSpareThreshold;
  final int percentageUsed;
  final int dataUnitsRead;
  final int dataUnitsWritten;
  final int hostReadCommands;
  final int hostWriteCommands;
  final int controllerBusyMinutes;
  final int powerCycles;
  final int powerOnHours;
  final int unsafeShutdowns;
  final int mediaErrors;
  final int errorLogEntries;
  final int warningTempMinutes;
  final int criticalTempMinutes;

  /// Temperature sensors 1–8; 0 = not implemented.
  final List<int> sensorsKelvin;

  double get compositeCelsius => compositeKelvin - 273.15;
  int get bytesRead => dataUnitsRead * dataUnitBytes;
  int get bytesWritten => dataUnitsWritten * dataUnitBytes;

  /// Enabled critical warning bit numbers (byte 0). The UI translates them.
  List<int> get warnings => [
    for (var bit = 0; bit < 8; bit++)
      if (criticalWarning & (1 << bit) != 0) bit,
  ];

  /// Remaining life (%) = 100 − PercentageUsed, clamped to 0–100
  /// (`ParsePcieEndurance`).
  int get lifeRemaining => (100 - percentageUsed).clamp(0, 100);

  SsdHealth get health => SsdHealth.fromLife(lifeRemaining);
}
