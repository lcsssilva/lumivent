/// Minimal bus used by the controller (allows a test fake).
abstract interface class FuryBus {
  int readByte(int addr, int reg);
  int readWord(int addr, int reg);
  void writeByte(int addr, int reg, int value);
  void quick(int addr);
  void close();
}
