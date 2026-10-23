part of 'quickjs_interrupt.dart';

final class _RLimit extends Struct {
  @Uint64()
  external int current;

  @Uint64()
  external int maximum;
}
