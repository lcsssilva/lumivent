// QuickJS converts numeric literals and `parseFloat` with libc's `strtod`,
// which follows the process locale. On a pt-BR desktop, "0.05" is parsed as 0
// because the decimal separator is ',': every effect that uses decimals would
// render incorrectly. Force the C numeric locale before creating a JS context.
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

const _lcNumeric = 1; // glibc's LC_NUMERIC.

void useCNumericLocale() {
  if (!Platform.isLinux) return;
  try {
    final setlocale = DynamicLibrary.process()
        .lookupFunction<
          Pointer<Utf8> Function(Int32, Pointer<Utf8>),
          Pointer<Utf8> Function(int, Pointer<Utf8>)
        >('setlocale');
    final name = 'C'.toNativeUtf8();
    setlocale(_lcNumeric, name);
    malloc.free(name);
  } on Object {
    // Best effort: if the symbol or locale is unavailable, the JS engine keeps
    // the process locale (locales that use '.' still parse decimals).
  }
}
