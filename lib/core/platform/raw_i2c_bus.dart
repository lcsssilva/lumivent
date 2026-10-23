// Raw I²C access through /dev/i2c-N (i2c-dev) via I2C_RDWR, using dart:ffi
// on libc. This is the transport of devices that need packets larger than the
// SMBus limit (32 bytes) or plain I²C reads, such as the GPU RGB controller.
//
// Addresses 0x50–0x57 (memory SPD/EEPROM) are always rejected before any
// ioctl: accessing them can damage the module.
import 'dart:ffi';
import 'dart:io' show sleep;
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'i2c_transport.dart';
import 'i2c_msg.dart';
import 'i2c_rdwr_data.dart';
import 'raw_i2c_exception.dart';

const _oRdwr = 2;
const _i2cRdwr = 0x0707;
const _i2cMRd = 0x0001;
const _ewouldblock = 11;
const _lockEx = 2, _lockNb = 4, _lockUn = 8;

/// Longest wait for the adapter lock held by another handle.
const i2cLockTimeout = Duration(seconds: 1);

/// Maximum payload of one I²C message (`__u16 len`).
const i2cMaxMessageLength = 0xFFFF;

/// SPD addresses (0x50–0x57) must never be accessed.
bool isForbiddenI2cAddress(int addr) => addr >= 0x50 && addr <= 0x57;

typedef _OpenC = Int Function(Pointer<Utf8>, Int);
typedef _OpenD = int Function(Pointer<Utf8>, int);
typedef _CloseC = Int Function(Int);
typedef _CloseD = int Function(int);
typedef _IoctlC = Int Function(
  Int,
  UnsignedLong,
  VarArgs<(Pointer<I2cRdwrData>,)>,
);
typedef _IoctlD = int Function(int, int, Pointer<I2cRdwrData>);
typedef _ErrnoC = Pointer<Int> Function();
typedef _FlockC = Int Function(Int, Int);
typedef _FlockD = int Function(int, int);

final _libc = DynamicLibrary.process();
final _open = _libc.lookupFunction<_OpenC, _OpenD>('open');
final _close = _libc.lookupFunction<_CloseC, _CloseD>('close');
final _ioctl = _libc.lookupFunction<_IoctlC, _IoctlD>('ioctl');
final _flock = _libc.lookupFunction<_FlockC, _FlockD>('flock');
final _errnoLocation = _libc.lookupFunction<_ErrnoC, _ErrnoC>(
  '__errno_location',
);

int get _errno => _errnoLocation().value;

/// Raw I²C device at [address] on `/dev/i2c-N`.
///
/// Every operation is one `I2C_RDWR` transaction with a single message; Dart
/// FFI buffers are allocated per call and released even on error.
class RawI2cBus implements I2cTransport {
  RawI2cBus._(this.path, this.address, this._fd);

  final String path;
  final int address;
  final int _fd;
  bool _closed = false;

  /// Opens [path] and validates [address] before touching the bus.
  static RawI2cBus open(String path, {required int address}) {
    if (address < 0 || address > 0x7F) {
      throw ArgumentError('not a 7-bit I²C address: $address');
    }
    if (isForbiddenI2cAddress(address)) {
      throw ArgumentError(
        'address 0x${address.toRadixString(16)} is SPD: access denied',
      );
    }
    final c = path.toNativeUtf8();
    try {
      final fd = _open(c, _oRdwr);
      if (fd < 0) throw RawI2cException('open($path)', _errno);
      return RawI2cBus._(path, address, fd);
    } finally {
      malloc.free(c);
    }
  }

  @override
  void write(Uint8List data) {
    _check(data.length);
    final buf = malloc<Uint8>(data.length);
    final msg = calloc<I2cMsg>();
    final args = calloc<I2cRdwrData>();
    try {
      buf.asTypedList(data.length).setAll(0, data);
      msg.ref
        ..addr = address
        ..flags = 0
        ..len = data.length
        ..buf = buf;
      args.ref
        ..msgs = msg
        ..nmsgs = 1;
      if (_ioctl(_fd, _i2cRdwr, args) < 0) {
        throw RawI2cException('write 0x${address.toRadixString(16)}', _errno);
      }
    } finally {
      calloc.free(args);
      calloc.free(msg);
      malloc.free(buf);
    }
  }

  @override
  Uint8List read(int length) {
    _check(length);
    final buf = malloc<Uint8>(length);
    final msg = calloc<I2cMsg>();
    final args = calloc<I2cRdwrData>();
    try {
      msg.ref
        ..addr = address
        ..flags = _i2cMRd
        ..len = length
        ..buf = buf;
      args.ref
        ..msgs = msg
        ..nmsgs = 1;
      if (_ioctl(_fd, _i2cRdwr, args) < 0) {
        throw RawI2cException('read 0x${address.toRadixString(16)}', _errno);
      }
      return Uint8List.fromList(buf.asTypedList(length));
    } finally {
      calloc.free(args);
      calloc.free(msg);
      malloc.free(buf);
    }
  }

  @override
  T exclusive<T>(T Function() body) {
    if (_closed) throw StateError('I²C bus is already closed: $path');
    // Non-blocking attempts with a deadline: a stuck holder must not freeze
    // the calling isolate. Holders keep the lock for one transfer pair only.
    final watch = Stopwatch()..start();
    while (_flock(_fd, _lockEx | _lockNb) < 0) {
      final err = _errno;
      if (err != _ewouldblock || watch.elapsed > i2cLockTimeout) {
        throw RawI2cException('flock($path)', err);
      }
      sleep(const Duration(milliseconds: 2));
    }
    try {
      return body();
    } finally {
      _flock(_fd, _lockUn);
    }
  }

  void _check(int length) {
    if (_closed) throw StateError('I²C bus is already closed: $path');
    if (length <= 0 || length > i2cMaxMessageLength) {
      throw ArgumentError('I²C message length out of range: $length');
    }
  }

  @override
  void close() {
    if (_closed) return;
    _closed = true;
    _close(_fd);
  }
}
