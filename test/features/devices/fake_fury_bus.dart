import 'package:lumivent/core/platform/smbus.dart';
import 'package:lumivent/features/devices/infrastructure/drivers/kingston_fury/fury_bus.dart';
import 'package:lumivent/features/devices/infrastructure/drivers/kingston_fury/protocol.dart';

class FakeFuryBus implements FuryBus {
  FakeFuryBus({this.dd = 0x00, this.id = const [0x46, 0x55, 0x52, 0x59]});
  int dd;
  List<int> id;
  bool failNext = false;
  bool failAlways = false;
  bool failOnReadWord = false;
  bool closed = false;
  final ops = <String>[];

  void _maybeFail() {
    if (failAlways) throw SmbusException('falha', 5);
    if (failNext) {
      failNext = false;
      throw SmbusException('falha', 5);
    }
  }

  @override
  int readByte(int a, int r) {
    ops.add('R $a ${r.toRadixString(16)}');
    _maybeFail();
    return r == furyGuardRegister ? dd : 0;
  }

  @override
  int readWord(int a, int r) {
    ops.add('RW $a ${r.toRadixString(16)}');
    _maybeFail();
    if (failOnReadWord) throw SmbusException('read failed', 5);
    return (id[r - 1] << 8) | 0x34;
  }

  @override
  void writeByte(int a, int r, int v) {
    ops.add('W $a ${r.toRadixString(16)}=${v.toRadixString(16)}');
    _maybeFail();
  }

  @override
  void quick(int a) {
    ops.add('Q $a');
    _maybeFail();
  }

  @override
  void close() => closed = true;

  List<String> get writes => ops.where((o) => o.startsWith('W')).toList();
}
