import 'dart:typed_data';

import 'package:lumivent/features/monitoring/monitoring.dart';

NvmeSmartLog smartLog({
  int criticalWarning = 0,
  int percentageUsed = 2,
  int dataUnitsWritten = 0,
}) => NvmeSmartLog(
  criticalWarning: criticalWarning,
  compositeKelvin: 314,
  availableSpare: 100,
  availableSpareThreshold: 10,
  percentageUsed: percentageUsed,
  dataUnitsRead: 0,
  dataUnitsWritten: dataUnitsWritten,
  hostReadCommands: 0,
  hostWriteCommands: 0,
  controllerBusyMinutes: 0,
  powerCycles: 0,
  powerOnHours: 0,
  unsafeShutdowns: 0,
  mediaErrors: 0,
  errorLogEntries: 0,
  warningTempMinutes: 0,
  criticalTempMinutes: 0,
  sensorsKelvin: const [0, 0, 0, 0, 0, 0, 0, 0],
);

/// 512-byte 02h log with known values (layout NVMe 1.4, little endian).
Uint8List smartLogBytes() {
  final b = Uint8List(512);
  final d = ByteData.sublistView(b);
  b[0] = 0x00; // critical warning
  d.setUint16(1, 314, Endian.little); // 40,85 °C
  b[3] = 100; // spare
  b[4] = 10; // limite do spare
  b[5] = 2; // porcentagem usada
  d.setUint64(32, 23456789, Endian.little); // data units lidas
  d.setUint64(48, 24218750, Endian.little); // escritas: 12,4 TB
  d.setUint64(64, 111, Endian.little);
  d.setUint64(80, 222, Endian.little);
  d.setUint64(96, 333, Endian.little);
  d.setUint64(112, 1234, Endian.little); // ciclos
  d.setUint64(128, 1820, Endian.little); // horas ligado
  d.setUint64(144, 56, Endian.little); // desligamentos inseguros
  d.setUint64(160, 0, Endian.little); // media errors
  d.setUint64(176, 7, Endian.little);
  d.setUint32(192, 3, Endian.little);
  d.setUint32(196, 1, Endian.little);
  d.setUint16(200, 315, Endian.little); // sensor 1
  d.setUint16(202, 326, Endian.little); // sensor 2
  return b;
}

String toHex(List<int> b) =>
    b.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
