import 'dart:ffi';

final class RLimit extends Struct {
  @Uint64()
  external int current;

  @Uint64()
  external int maximum;
}
