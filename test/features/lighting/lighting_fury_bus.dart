part of 'lighting_test.dart';

class _LightingFuryBus implements FuryBus {
  final writes = <(int, int, int)>[];
  int opens = 0;

  /// Guard value read from [ddAddress] (all addresses when null).
  int dd = 0;
  int? ddAddress;
  static const _id = [0x46, 0x55, 0x52, 0x59];
  @override
  int readByte(int addr, int reg) =>
      reg == 0xDD && (ddAddress == null || ddAddress == addr) ? dd : 0;
  @override
  int readWord(int addr, int reg) => (_id[reg - 1] << 8) | 0x34;
  @override
  void writeByte(int addr, int reg, int value) =>
      writes.add((addr, reg, value));
  @override
  void quick(int addr) {}
  @override
  void close() {}
}
