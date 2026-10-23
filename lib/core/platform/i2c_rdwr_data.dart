part of 'raw_i2c_bus.dart';

final class _I2cRdwrData extends Struct {
  external Pointer<_I2cMsg> msgs;

  @Uint32()
  external int nmsgs;
}
