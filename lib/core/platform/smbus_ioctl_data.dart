import 'dart:ffi';

final class SmbusIoctlData extends Struct {
  @Uint8()
  external int readWrite;
  @Uint8()
  external int command;
  @Uint32()
  external int size;
  external Pointer<Uint8> data; // union i2c_smbus_data (34 bytes)
}
