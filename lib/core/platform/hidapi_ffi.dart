// Minimal hidapi binding (hidraw backend) through dart:ffi.
//
// Only what drivers need: enumerate, open by path, feature
// reports (sending and reading), input reports, and output reports.
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

final class _HidDeviceInfo extends Struct {
  external Pointer<Utf8> path;
  @UnsignedShort()
  external int vendorId;
  @UnsignedShort()
  external int productId;
  external Pointer<Int32> serialNumber; // wchar_t* (4 bytes on Linux)
  @UnsignedShort()
  external int releaseNumber;
  external Pointer<Int32> manufacturerString;
  external Pointer<Int32> productString;
  @UnsignedShort()
  external int usagePage;
  @UnsignedShort()
  external int usage;
  @Int()
  external int interfaceNumber;
  external Pointer<_HidDeviceInfo> next;
  @Int()
  external int busType;
}

final class _HidDevice extends Opaque {}

typedef _InitC = Int Function();
typedef _InitD = int Function();
typedef _EnumC = Pointer<_HidDeviceInfo> Function(UnsignedShort, UnsignedShort);
typedef _EnumD = Pointer<_HidDeviceInfo> Function(int, int);
typedef _FreeEnumC = Void Function(Pointer<_HidDeviceInfo>);
typedef _FreeEnumD = void Function(Pointer<_HidDeviceInfo>);
typedef _OpenPathC = Pointer<_HidDevice> Function(Pointer<Utf8>);
typedef _OpenPathD = Pointer<_HidDevice> Function(Pointer<Utf8>);
typedef _CloseC = Void Function(Pointer<_HidDevice>);
typedef _CloseD = void Function(Pointer<_HidDevice>);
typedef _IoC = Int Function(Pointer<_HidDevice>, Pointer<Uint8>, Size);
typedef _IoD = int Function(Pointer<_HidDevice>, Pointer<Uint8>, int);
typedef _ReadTimeoutC = Int Function(
  Pointer<_HidDevice>,
  Pointer<Uint8>,
  Size,
  Int,
);
typedef _ReadTimeoutD = int Function(
  Pointer<_HidDevice>,
  Pointer<Uint8>,
  int,
  int,
);
typedef _ErrorC = Pointer<Int32> Function(Pointer<_HidDevice>);
typedef _ErrorD = Pointer<Int32> Function(Pointer<_HidDevice>);

String? _wstr(Pointer<Int32> p) {
  if (p == nullptr) return null;
  final codes = <int>[];
  for (var i = 0; p[i] != 0; i++) {
    codes.add(p[i]);
  }
  return String.fromCharCodes(codes);
}

class HidDeviceInfo {
  HidDeviceInfo({
    required this.path,
    required this.vendorId,
    required this.productId,
    required this.usagePage,
    required this.usage,
    required this.interfaceNumber,
    this.product,
    this.manufacturer,
    this.serial,
  });

  final String path;
  final int vendorId, productId, usagePage, usage, interfaceNumber;
  final String? product, manufacturer, serial;

  @override
  String toString() =>
      '$path ${_hex16(vendorId)}:${_hex16(productId)} if=$interfaceNumber '
      'usage=${_hex16(usagePage)}/${_hex16(usage)} "$product"';
}

String _hex16(int v) => v.toRadixString(16).padLeft(4, '0');

class HidException implements Exception {
  HidException(this.message);
  final String message;
  @override
  String toString() => 'HidException: $message';
}

class HidApi {
  HidApi._(DynamicLibrary lib)
    : _init = lib.lookupFunction<_InitC, _InitD>('hid_init'),
      _exit = lib.lookupFunction<_InitC, _InitD>('hid_exit'),
      _enumerate = lib.lookupFunction<_EnumC, _EnumD>('hid_enumerate'),
      _freeEnum = lib.lookupFunction<_FreeEnumC, _FreeEnumD>(
        'hid_free_enumeration',
      ),
      _openPath = lib.lookupFunction<_OpenPathC, _OpenPathD>('hid_open_path'),
      _close = lib.lookupFunction<_CloseC, _CloseD>('hid_close'),
      _sendFeature = lib.lookupFunction<_IoC, _IoD>('hid_send_feature_report'),
      _getFeature = lib.lookupFunction<_IoC, _IoD>('hid_get_feature_report'),
      _getInput = lib.lookupFunction<_IoC, _IoD>('hid_get_input_report'),
      _write = lib.lookupFunction<_IoC, _IoD>('hid_write'),
      _readTimeout = lib.lookupFunction<_ReadTimeoutC, _ReadTimeoutD>(
        'hid_read_timeout',
      ),
      _error = lib.lookupFunction<_ErrorC, _ErrorD>('hid_error') {
    if (_init() != 0) throw HidException('hid_init failed');
  }

  static HidApi open() =>
      HidApi._(DynamicLibrary.open('libhidapi-hidraw.so.0'));

  final _InitD _init, _exit;
  final _EnumD _enumerate;
  final _FreeEnumD _freeEnum;
  final _OpenPathD _openPath;
  final _CloseD _close;
  final _IoD _sendFeature, _getFeature, _getInput, _write;
  final _ReadTimeoutD _readTimeout;
  final _ErrorD _error;

  List<HidDeviceInfo> enumerate({int vendorId = 0, int productId = 0}) {
    final head = _enumerate(vendorId, productId);
    final out = <HidDeviceInfo>[];
    for (var p = head; p != nullptr; p = p.ref.next) {
      final d = p.ref;
      out.add(
        HidDeviceInfo(
          path: d.path.toDartString(),
          vendorId: d.vendorId,
          productId: d.productId,
          usagePage: d.usagePage,
          usage: d.usage,
          interfaceNumber: d.interfaceNumber,
          product: _wstr(d.productString),
          manufacturer: _wstr(d.manufacturerString),
          serial: _wstr(d.serialNumber),
        ),
      );
    }
    if (head != nullptr) _freeEnum(head);
    return out;
  }

  HidDevice openPath(String path) {
    final cPath = path.toNativeUtf8();
    try {
      final dev = _openPath(cPath);
      if (dev == nullptr) {
        throw HidException('hid_open_path($path): ${_wstr(_error(nullptr))}');
      }
      return HidDevice._(this, dev, path);
    } finally {
      malloc.free(cPath);
    }
  }

  void dispose() => _exit();
}

class HidDevice {
  HidDevice._(this._api, this._dev, this.path);

  final HidApi _api;
  final Pointer<_HidDevice> _dev;
  final String path;
  bool _closed = false;

  String get _lastError => _wstr(_api._error(_dev)) ?? 'unknown error';

  /// Sends a feature report. [data] starts with the report ID and is padded
  /// with zeroes up to [length].
  void sendFeature(List<int> data, int length) {
    _io(_api._sendFeature, data, length, 'hid_send_feature_report');
  }

  /// Reads a feature report with the given [reportId]. Returns the bytes read,
  /// including the report ID.
  Uint8List getFeature(int reportId, int length) =>
      _ioRead(_api._getFeature, reportId, length, 'hid_get_feature_report');

  /// Reads an input report (GET_REPORT through EP0) with the given [reportId].
  Uint8List getInput(int reportId, int length) =>
      _ioRead(_api._getInput, reportId, length, 'hid_get_input_report');

  /// Sends an output report through the interrupt endpoint.
  void write(List<int> data, int length) {
    _io(_api._write, data, length, 'hid_write');
  }

  // Not unit-tested (REV-008): a HidDevice only exists after a real hidapi
  // open, and _checkLength is a private one-line guard. Testing it would mean
  // widening the API or opening hardware, so the guards are reviewed here.
  /// Reads an input report from the interrupt endpoint; empty on timeout.
  Uint8List read(int length, {int timeoutMs = 100}) {
    _checkOpen();
    _checkLength(length, 'hid_read_timeout');
    final buf = calloc<Uint8>(length);
    try {
      final n = _api._readTimeout(_dev, buf, length, timeoutMs);
      if (n < 0) throw HidException('hid_read_timeout: $_lastError');
      return Uint8List.fromList(buf.asTypedList(n));
    } finally {
      calloc.free(buf);
    }
  }

  void _io(_IoD fn, List<int> data, int length, String name) {
    _checkOpen();
    if (data.length > length) {
      throw ArgumentError('$name: ${data.length} bytes > $length-byte report');
    }
    final buf = calloc<Uint8>(length);
    try {
      buf.asTypedList(length).setAll(0, data);
      final n = fn(_dev, buf, length);
      if (n < 0) throw HidException('$name: $_lastError');
    } finally {
      calloc.free(buf);
    }
  }

  Uint8List _ioRead(_IoD fn, int reportId, int length, String name) {
    _checkOpen();
    _checkLength(length, name);
    final buf = calloc<Uint8>(length);
    try {
      buf[0] = reportId;
      final n = fn(_dev, buf, length);
      if (n < 0) throw HidException('$name: $_lastError');
      return Uint8List.fromList(buf.asTypedList(n));
    } finally {
      calloc.free(buf);
    }
  }

  void _checkOpen() {
    if (_closed) throw StateError('HidDevice is already closed: $path');
  }

  // A read needs at least the report ID byte.
  static void _checkLength(int length, String name) {
    if (length <= 0) throw ArgumentError('$name: length must be positive');
  }

  void close() {
    if (_closed) return;
    _closed = true;
    _api._close(_dev);
  }
}
