// SMBus access through /dev/i2c-N (i2c-dev) via ioctl, using dart:ffi on libc.
//
// Operations: byte/word reads, byte writes, and quick write (ACK pre-check).
// Addresses 0x50–0x57 (memory SPD/EEPROM) are always rejected before any ioctl:
// accessing them can damage the module.
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

const _oRdwr = 2;
const _i2cSlave = 0x0703;
const _i2cSmbus = 0x0720;
const _smbusWrite = 0, _smbusRead = 1;
const _smbusQuick = 0, _smbusByteData = 2, _smbusWordData = 3;
const _eacces = 13, _eperm = 1;

/// SPD addresses (0x50–0x57) must never be accessed.
bool isForbiddenSmbusAddress(int addr) => addr >= 0x50 && addr <= 0x57;

/// Finds the `/dev/i2c-N` whose adapter has exactly this [name]
/// (`/sys/class/i2c-dev/i2c-N/name`). The number changes between boots.
String? findI2cBusByName(String name, {String sysfsRoot = '/sys'}) {
  final dir = Directory('$sysfsRoot/class/i2c-dev');
  if (!dir.existsSync()) return null;
  for (final e in dir.listSync()) {
    final f = File('${e.path}/name');
    if (f.existsSync() && f.readAsStringSync().trim() == name) {
      return '/dev/${e.uri.pathSegments.where((s) => s.isNotEmpty).last}';
    }
  }
  return null;
}

final class _SmbusIoctlData extends Struct {
  @Uint8()
  external int readWrite;
  @Uint8()
  external int command;
  @Uint32()
  external int size;
  external Pointer<Uint8> data; // union i2c_smbus_data (34 bytes)
}

typedef _OpenC = Int Function(Pointer<Utf8>, Int);
typedef _OpenD = int Function(Pointer<Utf8>, int);
typedef _CloseC = Int Function(Int);
typedef _CloseD = int Function(int);
typedef _IoctlLongC = Int Function(Int, UnsignedLong, VarArgs<(Long,)>);
typedef _IoctlLongD = int Function(int, int, int);
typedef _IoctlPtrC = Int Function(
  Int,
  UnsignedLong,
  VarArgs<(Pointer<_SmbusIoctlData>,)>,
);
typedef _IoctlPtrD = int Function(int, int, Pointer<_SmbusIoctlData>);
typedef _ErrnoC = Pointer<Int> Function();

final _libc = DynamicLibrary.process();
final _open = _libc.lookupFunction<_OpenC, _OpenD>('open');
final _close = _libc.lookupFunction<_CloseC, _CloseD>('close');
final _ioctlLong = _libc.lookupFunction<_IoctlLongC, _IoctlLongD>('ioctl');
final _ioctlPtr = _libc.lookupFunction<_IoctlPtrC, _IoctlPtrD>('ioctl');
final _errnoLocation = _libc.lookupFunction<_ErrnoC, _ErrnoC>(
  '__errno_location',
);

int get _errno => _errnoLocation().value;

class SmbusException implements Exception {
  SmbusException(this.message, this.errno);
  final String message;
  final int errno;
  bool get permissionDenied => errno == _eacces || errno == _eperm;
  @override
  String toString() => 'SmbusException: $message (errno $errno)';
}

class SmBus {
  SmBus._(this.path, this._fd);

  final String path;
  final int _fd;
  bool _closed = false;

  /// Address of the last successful `I2C_SLAVE`; the ioctl is redone only when
  /// it changes (and after any error).
  int? _slaveAddr;

  /// Native buffers allocated once per bus and released in [close].
  final Pointer<_SmbusIoctlData> _args = calloc<_SmbusIoctlData>();
  final Pointer<Uint8> _data = calloc<Uint8>(34);

  static SmBus open(String path) {
    final c = path.toNativeUtf8();
    try {
      final fd = _open(c, _oRdwr);
      if (fd < 0) throw SmbusException('open($path)', _errno);
      return SmBus._(path, fd);
    } finally {
      malloc.free(c);
    }
  }

  /// Reads register [reg] from the device at [addr]. Throws [SmbusException]
  /// if no device responds (NACK) or the bus fails.
  int readByteData(int addr, int reg) {
    final d = _xfer(addr, _smbusRead, reg, _smbusByteData, 'read', null);
    return d[0];
  }

  /// Reads a WORD (little-endian, as provided by i2c-dev) from register [reg].
  int readWordData(int addr, int reg) {
    final d = _xfer(addr, _smbusRead, reg, _smbusWordData, 'read word', null);
    return d[0] | (d[1] << 8);
  }

  /// Writes [value] to register [reg] of the device at [addr].
  void writeByteData(int addr, int reg, int value) {
    if (value < 0 || value > 0xFF) {
      throw ArgumentError('byte outside 0..255: $value');
    }
    _xfer(addr, _smbusWrite, reg, _smbusByteData, 'write', value);
  }

  /// Quick write (address only): checks the ACK. Throws [SmbusException] on NACK.
  void writeQuick(int addr) {
    _xfer(addr, _smbusWrite, 0, _smbusQuick, 'quick write', null);
  }

  /// Executes a transfer; the address guard runs before any ioctl.
  List<int> _xfer(
    int addr,
    int rw,
    int reg,
    int size,
    String what,
    int? value,
  ) {
    if (_closed) throw StateError('SmBus is already closed: $path');
    if (isForbiddenSmbusAddress(addr)) {
      throw ArgumentError(
        'address 0x${addr.toRadixString(16)} is SPD: access denied',
      );
    }
    if (reg < 0 || reg > 0xFF) {
      throw ArgumentError('register outside 0..255: $reg');
    }
    final where = '0x${addr.toRadixString(16)}/0x${reg.toRadixString(16)}';
    if (_slaveAddr != addr) {
      _slaveAddr = null;
      if (_ioctlLong(_fd, _i2cSlave, addr) < 0) {
        throw SmbusException('I2C_SLAVE 0x${addr.toRadixString(16)}', _errno);
      }
      _slaveAddr = addr;
    }
    final args = _args;
    final data = _data;
    data[0] = value ?? 0;
    data[1] = 0;
    args.ref
      ..readWrite = rw
      ..command = reg
      ..size = size
      ..data = size == _smbusQuick ? nullptr : data;
    if (_ioctlPtr(_fd, _i2cSmbus, args) < 0) {
      final errno = _errno;
      _slaveAddr = null; // state unknown after an error: redo I2C_SLAVE
      throw SmbusException('$what $where', errno);
    }
    return [data[0], data[1]];
  }

  void close() {
    if (_closed) return;
    _closed = true;
    _close(_fd);
    calloc.free(_data);
    calloc.free(_args);
  }
}
