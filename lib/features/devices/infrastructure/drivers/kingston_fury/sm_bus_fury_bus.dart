import '../../../../../core/platform/smbus.dart';
import 'protocol.dart';
import 'fury_bus.dart';

/// Adapter for the real [SmBus].
class SmBusFuryBus implements FuryBus {
  SmBusFuryBus(this._bus);
  final SmBus _bus;

  /// Opens the adapter by name (the `/dev/i2c-N` number changes). Throws
  /// [SmbusException] if it is not found.
  static SmBusFuryBus openByName({String sysfsRoot = '/sys'}) {
    final path = findI2cBusByName(furyBusName, sysfsRoot: sysfsRoot);
    if (path == null) {
      throw SmbusException('adaptador "$furyBusName" ausente', 2);
    }
    return SmBusFuryBus(SmBus.open(path));
  }

  @override
  int readByte(int addr, int reg) => _bus.readByteData(addr, reg);
  @override
  int readWord(int addr, int reg) => _bus.readWordData(addr, reg);
  @override
  void writeByte(int addr, int reg, int value) =>
      _bus.writeByteData(addr, reg, value);
  @override
  void quick(int addr) => _bus.writeQuick(addr);
  @override
  void close() => _bus.close();
}
