import 'dart:ffi';

import 'i2c_msg.dart';

final class I2cRdwrData extends Struct {
  external Pointer<I2cMsg> msgs;

  @Uint32()
  external int nmsgs;
}
