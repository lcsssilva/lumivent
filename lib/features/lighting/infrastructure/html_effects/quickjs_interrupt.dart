// Deadline for QuickJS scripts through `JS_SetInterruptHandler`.
//
// flutter_js 0.8.7 accepts a `timeout` but its bridge (`jsNewRuntime`) never
// installs an interrupt handler, so `while (true) {}` runs forever inside the
// FFI call. Killing an isolate cannot stop native code, so Linux app builds
// also run QuickJS in a child process that the parent can kill. The bridge
// exports `JS_SetInterruptHandler`, which stops ordinary loops before that
// process-level hard stop is needed.
//
// QuickJS polls the handler every ~10 000 bytecode steps on the thread running
// the script (measured overhead < 1 %). A non-zero return raises an
// uncatchable `InternalError: interrupted`, `evaluate` returns, and the runtime
// stays usable.
//
// The runtime pointer comes from flutter_js's `runtimeOpaques` map, which is
// not a documented API: pubspec pins flutter_js to 0.8.7 because of it.

import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_js/flutter_js.dart';
import 'package:flutter_js/quickjs/ffi.dart' show runtimeOpaques;

final class _RLimit extends Struct {
  @Uint64()
  external int current;

  @Uint64()
  external int maximum;
}

typedef _GetRLimitNative = Int32 Function(
  Int32 resource,
  Pointer<_RLimit> limit,
);
typedef _GetRLimit = int Function(int resource, Pointer<_RLimit> limit);
typedef _SetRLimitNative = Int32 Function(
  Int32 resource,
  Pointer<_RLimit> limit,
);
typedef _SetRLimit = int Function(int resource, Pointer<_RLimit> limit);

typedef _HandlerNative = Int32 Function(Pointer<Void> rt, Pointer<Void> opaque);
typedef _SetHandlerNative = Void Function(
  Pointer<Void> rt,
  Pointer<NativeFunction<_HandlerNative>> handler,
  Pointer<Void> opaque,
);
typedef _SetHandler = void Function(
  Pointer<Void> rt,
  Pointer<NativeFunction<_HandlerNative>> handler,
  Pointer<Void> opaque,
);

typedef _SetRuntimeLimitNative = Void Function(Pointer<Void> rt, Size limit);
typedef _SetRuntimeLimit = void Function(Pointer<Void> rt, int limit);

/// Per-isolate state: the handler runs synchronously on the isolate that is
/// evaluating the script, so plain statics are enough.
final _clock = Stopwatch()..start();
int _deadlineUs = _noDeadline;
const _noDeadline = 1 << 62;
const _memoryLimitBytes = 96 * 1024 * 1024;
const _stackLimitBytes = 2 * 1024 * 1024;
const _addressSpaceHeadroomBytes = 512 * 1024 * 1024;

/// Adds an address-space ceiling around the worker process after the Flutter
/// VM has started, so native allocations cannot grow without bound.
void limitWorkerAddressSpace() {
  if (!Platform.isLinux) {
    throw UnsupportedError('the effect worker requires Linux');
  }
  final currentBytes = virtualMemoryBytes(
    File('/proc/self/status').readAsStringSync(),
  );
  final limit = calloc<_RLimit>();
  try {
    final libc = DynamicLibrary.process();
    final getRLimit = libc.lookupFunction<_GetRLimitNative, _GetRLimit>(
      'getrlimit',
    );
    final setRLimit = libc.lookupFunction<_SetRLimitNative, _SetRLimit>(
      'setrlimit',
    );
    const resourceAs = 9;
    if (getRLimit(resourceAs, limit) != 0) {
      throw StateError('could not inspect worker address-space limit');
    }
    final hardLimit = limit.ref.maximum;
    var target = currentBytes + _addressSpaceHeadroomBytes;
    if (hardLimit > 0 && target > hardLimit) target = hardLimit;
    if (target <= currentBytes) {
      throw UnsupportedError(
        'worker address-space limit is below its current usage',
      );
    }
    limit.ref.current = target;
    if (setRLimit(resourceAs, limit) != 0) {
      throw StateError('could not bound worker address space');
    }
  } finally {
    calloc.free(limit);
  }
}

/// Current address-space size from the text of `/proc/<pid>/status`.
///
/// `VmSize` is reported in kB, so the result does not depend on the kernel
/// page size (`/proc/self/statm` counts pages, 4, 16 or 64 KiB each).
@visibleForTesting
int virtualMemoryBytes(String procStatus) {
  for (final line in const LineSplitter().convert(procStatus)) {
    if (!line.startsWith('VmSize:')) continue;
    final fields = line
        .substring('VmSize:'.length)
        .trim()
        .split(RegExp(r'\s+'));
    final kilobytes = int.tryParse(fields.first);
    if (fields.length == 2 && fields.last == 'kB' && kilobytes != null) {
      return kilobytes * 1024;
    }
  }
  throw const FormatException('could not read worker address space');
}

int _onInterrupt(Pointer<Void> rt, Pointer<Void> opaque) =>
    _clock.elapsedMicroseconds > _deadlineUs ? 1 : 0;

_SetHandler? _setHandler;
_SetRuntimeLimit? _setMemoryLimit;
_SetRuntimeLimit? _setMaxStackSize;

void _loadQuickJsSettings() {
  if (_setHandler != null &&
      _setMemoryLimit != null &&
      _setMaxStackSize != null) {
    return;
  }
  if (!Platform.isLinux) return;
  // Same library and lookup order as flutter_js (`quickjs/ffi.dart`).
  final env = Platform.environment;
  final name = env['FLUTTER_TEST'] == 'true'
      ? env['LIBQUICKJSC_TEST_PATH']
      : env['LIBQUICKJSC_PATH'];
  final lib = DynamicLibrary.open(name ?? 'libquickjs_c_bridge_plugin.so');
  _setHandler = lib.lookupFunction<_SetHandlerNative, _SetHandler>(
    'JS_SetInterruptHandler',
  );
  _setMemoryLimit = lib
      .lookupFunction<_SetRuntimeLimitNative, _SetRuntimeLimit>(
        'JS_SetMemoryLimit',
      );
  _setMaxStackSize = lib
      .lookupFunction<_SetRuntimeLimitNative, _SetRuntimeLimit>(
        'JS_SetMaxStackSize',
      );
}

/// Creates a QuickJS runtime with CPU, memory, and stack limits installed.
///
/// Throws [UnsupportedError] when the native limits cannot be installed:
/// running an effect without them could exhaust or hang the app.
QuickJsRuntime2 newInterruptibleQuickJs() {
  // flutter_js registers every native runtime in `runtimeOpaques` by the
  // runtime's native pointer. After a runtime is freed, the allocator can
  // hand the same address to the next runtime (observed in the test run), so
  // the new registration must be detected by comparing the mapped opaque
  // objects, not by a set difference of keys: a reused address overwrites the
  // map entry in place and leaves no new key behind. Without this, any load
  // that follows a failed load would wrongly report that the limits could
  // not be installed.
  final registered = Map.of(runtimeOpaques);
  final js = QuickJsRuntime2();
  // The native runtime is created lazily on the first evaluation.
  try {
    js.evaluate('0');
  } on Object {
    js.dispose();
    rethrow;
  }
  final created = <Pointer<Void>>[];
  runtimeOpaques.forEach((key, opaque) {
    if (!identical(registered[key], opaque)) {
      created.add(key.cast<Void>());
    }
  });
  try {
    _loadQuickJsSettings();
  } on Object {
    js.dispose();
    rethrow;
  }
  final setHandler = _setHandler;
  final setMemoryLimit = _setMemoryLimit;
  final setMaxStackSize = _setMaxStackSize;
  if (created.length != 1 || setHandler == null) {
    js.dispose();
    throw UnsupportedError('could not install the QuickJS time limit');
  }
  if (setMemoryLimit == null || setMaxStackSize == null) {
    js.dispose();
    throw UnsupportedError('could not install the QuickJS resource limits');
  }
  final runtime = created.single;
  try {
    setMemoryLimit(runtime, _memoryLimitBytes);
    setMaxStackSize(runtime, _stackLimitBytes);
    setHandler(
      runtime,
      Pointer.fromFunction<_HandlerNative>(_onInterrupt, 0),
      nullptr,
    );
  } on Object {
    js.dispose();
    rethrow;
  }
  return js;
}

/// Runs [body] with a script deadline of [limit]; scripts still running after
/// it are interrupted with `InternalError: interrupted`.
T withScriptDeadline<T>(Duration limit, T Function() body) {
  _deadlineUs = _clock.elapsedMicroseconds + limit.inMicroseconds;
  try {
    return body();
  } finally {
    _deadlineUs = _noDeadline;
  }
}
