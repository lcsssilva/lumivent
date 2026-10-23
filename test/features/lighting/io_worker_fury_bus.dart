import 'package:lumivent/features/devices/infrastructure/drivers/kingston_fury/fury_bus.dart';

class IoWorkerFuryBus implements FuryBus {
  final writes = <(int, int, int)>[];
  bool closed = false;

  /// Guard value read at [guarded] (every address when null).
  int dd = 0;
  int? guarded;
  static const _id = [0x46, 0x55, 0x52, 0x59];
  @override
  int readByte(int addr, int reg) =>
      reg == 0xDD && (guarded == null || guarded == addr) ? dd : 0;
  @override
  int readWord(int addr, int reg) => (_id[reg - 1] << 8) | 0x34;
  @override
  void writeByte(int addr, int reg, int value) =>
      writes.add((addr, reg, value));
  @override
  void quick(int addr) {}
  @override
  void close() => closed = true;
}
