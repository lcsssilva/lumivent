// Minimal hidapi binding (hidraw backend) through dart:ffi.
//
// Only what drivers need: enumerate, open by path, feature
// reports (sending and reading), input reports, and output reports.
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'hid_exception.dart';

part 'hid_device_info_struct.dart';
part 'hid_device_handle.dart';
part 'hid_device_info.dart';
part 'hid_device.dart';

typedef _InitC = Int Function();
typedef _InitD = int Function();
typedef _EnumC = Pointer<_HidDeviceInfoStruct> Function(
  UnsignedShort,
  UnsignedShort,
);
typedef _EnumD = Pointer<_HidDeviceInfoStruct> Function(int, int);
typedef _FreeEnumC = Void Function(Pointer<_HidDeviceInfoStruct>);
typedef _FreeEnumD = void Function(Pointer<_HidDeviceInfoStruct>);
typedef _OpenPathC = Pointer<_HidDeviceHandle> Function(Pointer<Utf8>);
typedef _OpenPathD = Pointer<_HidDeviceHandle> Function(Pointer<Utf8>);
typedef _CloseC = Void Function(Pointer<_HidDeviceHandle>);
typedef _CloseD = void Function(Pointer<_HidDeviceHandle>);
typedef _IoC = Int Function(Pointer<_HidDeviceHandle>, Pointer<Uint8>, Size);
typedef _IoD = int Function(Pointer<_HidDeviceHandle>, Pointer<Uint8>, int);
typedef _ReadTimeoutC = Int Function(
  Pointer<_HidDeviceHandle>,
  Pointer<Uint8>,
  Size,
  Int,
);
typedef _ReadTimeoutD = int Function(
  Pointer<_HidDeviceHandle>,
  Pointer<Uint8>,
  int,
  int,
);
typedef _ErrorC = Pointer<Int32> Function(Pointer<_HidDeviceHandle>);
typedef _ErrorD = Pointer<Int32> Function(Pointer<_HidDeviceHandle>);

String? _wstr(Pointer<Int32> p) {
  if (p == nullptr) return null;
  final codes = <int>[];
  for (var i = 0; p[i] != 0; i++) {
    codes.add(p[i]);
  }
  return String.fromCharCodes(codes);
}

String _hex16(int v) => v.toRadixString(16).padLeft(4, '0');

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
