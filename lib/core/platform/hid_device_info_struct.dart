import 'dart:ffi';

import 'package:ffi/ffi.dart';

final class HidDeviceInfoStruct extends Struct {
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
  external Pointer<HidDeviceInfoStruct> next;
  @Int()
  external int busType;
}
