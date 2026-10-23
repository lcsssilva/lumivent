part of 'smbus.dart';

final class _SmbusIoctlData extends Struct {
  @Uint8()
  external int readWrite;
  @Uint8()
  external int command;
  @Uint32()
  external int size;
  external Pointer<Uint8> data; // union i2c_smbus_data (34 bytes)
}
