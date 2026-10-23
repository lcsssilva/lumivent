import 'dart:ffi';

final class I2cMsg extends Struct {
  @Uint16()
  external int addr;

  @Uint16()
  external int flags;

  @Uint16()
  external int len;

  /// Explicit tail padding, as in the C `struct i2c_msg` on 64-bit.
  @Uint16()
  external int reserved;

  external Pointer<Uint8> buf;
}
