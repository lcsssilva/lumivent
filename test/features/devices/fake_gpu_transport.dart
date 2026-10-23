import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/core/platform/i2c_transport.dart';
import 'package:lumivent/core/platform/raw_i2c_exception.dart';

/// Fake transport with queued read answers. A read failure simulates the
/// `EIO` this kernel returns for the OEM bus, which is the current hardware
/// blocker (see docs/GPU-RX9060XT-protocolo.md).
class FakeGpuTransport implements I2cTransport {
  final writes = <Uint8List>[];
  final reads = <Uint8List>[];
  bool failRead = false;
  bool failWrite = false;
  bool closed = false;
  int readCalls = 0;

  /// Lock holds, and transfers made outside one.
  int locks = 0;
  int unlocked = 0;
  bool _held = false;

  /// Each lock hold as the sequence of transfers made inside it.
  final holds = <List<String>>[];

  @override
  T exclusive<T>(T Function() body) {
    expect(_held, isFalse, reason: 'the lock is not reentrant');
    locks++;
    holds.add([]);
    _held = true;
    try {
      return body();
    } finally {
      _held = false;
    }
  }

  void _transfer(String kind) {
    if (_held) {
      holds.last.add(kind);
    } else {
      unlocked++;
    }
  }

  @override
  void write(Uint8List data) {
    _transfer('w${data[0].toRadixString(16)}');
    writes.add(Uint8List.fromList(data));
    if (failWrite) throw RawI2cException('write', 5);
  }

  @override
  Uint8List read(int length) {
    _transfer('r');
    readCalls++;
    if (failRead) throw RawI2cException('read', 5);
    final data = reads.removeAt(0);
    return Uint8List.fromList(data.take(length).toList());
  }

  @override
  void close() => closed = true;
}
