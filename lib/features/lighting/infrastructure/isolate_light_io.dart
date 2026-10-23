import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import '../../devices/devices.dart';
import 'light_io_command.dart';
import 'light_io_request.dart';
import 'light_io_reply.dart';
import 'light_io_core.dart';
import 'light_io_client.dart';

// I/O worker of the lighting module.
//
// The ITE (hidraw feature reports, ~12 ms), the Kingston Fury (SMBus ioctl,
// ~30 ms) and the GPU (I²C, plus a mandatory 120 ms pause after every effect)
// drivers block the isolate that calls them. The engine isolate also streams
// the fans (asynchronous, 2 ms gaps that need a free event loop), so those
// drivers live in separate isolates: this worker. It is the only owner of
// `IteController`, `FuryController` and `GpuController` (FFI handles do not
// cross isolates), receives plain commands and answers each with `ok` and the
// measured duration. Each driver runs in its own instance of this worker
// ([LightIoKind]) so a slow bus never holds back the others. The AL V2 hub has
// its own worker (`isolate_alv2_hub_link.dart`).

// ── Protocol ───────────────────────────────────────────────────────────────

/// Whether the reply to [command] reports the Fury slot reasons
/// (`LightIoReply.ramReasons`).
bool reportsRamReasons(LightIoCommand command) =>
    command is IoRam || command is IoRamOff || command is IoInvalidate;

/// Whether the reply to [command] reports the GPU state
/// (`LightIoReply.gpuReason`), even when the GPU is usable (`null`).
bool reportsGpuReason(LightIoCommand command) =>
    command is IoInitGpu ||
    command is IoGpuStatic ||
    command is IoGpuEffect ||
    command is IoGpuOff ||
    command is IoInvalidate;

// ── Worker logic (no isolate: tests drive it directly) ─────────────────────

/// Which drivers an [IsolateLightIo] worker owns.
enum LightIoKind { board, ram, gpu }

// ── Clients ────────────────────────────────────────────────────────────────

/// Client of the real worker isolate, spawned lazily by the constructor (the
/// requests wait for it). Create it inside the engine isolate.
class IsolateLightIo implements LightIoClient {
  IsolateLightIo(this.kind) {
    _port = _start();
  }

  /// Which drivers this worker owns.
  final LightIoKind kind;

  final _rx = ReceivePort('lumivent-light-io-replies');
  final _pending = <int, Completer<LightIoReply>>{};
  late final Future<SendPort?> _port;
  Isolate? _isolate;
  int _next = 0;
  bool _disposed = false;

  Future<SendPort?> _start() async {
    final first = Completer<SendPort?>();
    _rx.listen((Object? m) {
      switch (m) {
        case SendPort():
          if (!first.isCompleted) first.complete(m);
        case LightIoReply():
          _pending.remove(m.id)?.complete(m);
        case null:
          // The worker exited: nobody will answer what is still pending.
          if (!first.isCompleted) first.complete(null);
          _failPending();
      }
    });
    try {
      _isolate = await Isolate.spawn(
        _workerMain,
        (_rx.sendPort, kind),
        debugName: 'lumivent-light-io-${kind.name}',
        onExit: _rx.sendPort,
      );
      if (_disposed) _isolate?.kill(priority: Isolate.immediate);
    } on Object catch (e, st) {
      stderr.writeln('lighting io: spawn failed: $e\n$st');
      if (!first.isCompleted) first.complete(null);
    }
    return first.future;
  }

  @override
  Future<LightIoReply> request(LightIoCommand command) async {
    final id = _next++;
    final done = Completer<LightIoReply>();
    _pending[id] = done;
    final port = await _port;
    if (port == null || _disposed) {
      _pending.remove(id);
      return LightIoReply.failed(id);
    }
    port.send(LightIoRequest(id, command));
    return done.future;
  }

  void _failPending() {
    for (final e in _pending.entries.toList()) {
      e.value.complete(LightIoReply.failed(e.key));
    }
    _pending.clear();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _isolate?.kill(priority: Isolate.immediate);
    _failPending();
    _rx.close();
  }
}

/// Worker isolate entry point: the only place where the drivers are opened.
Future<void> _workerMain((SendPort, LightIoKind) args) async {
  final (toEngine, kind) = args;
  final rx = ReceivePort('lumivent-light-io-${kind.name}');
  final core = switch (kind) {
    LightIoKind.board => LightIoCore(ite: IteController.open()),
    LightIoKind.ram => LightIoCore(fury: FuryController()),
    LightIoKind.gpu => _openGpuCore(),
  };
  toEngine.send(rx.sendPort);
  await for (final m in rx) {
    if (m is! LightIoRequest) continue;
    final reply = core.handle(m.id, m.command);
    unawaited(reply.then(toEngine.send));
    if (m.command is IoClose) {
      await reply;
      rx.close();
    }
  }
}

/// Opens the GPU controller inside its worker. A missing adapter/permission is
/// kept as the reason, so the UI can explain it without a second probe.
LightIoCore _openGpuCore() {
  try {
    return LightIoCore(gpu: GpuController.open());
  } on Object catch (e, st) {
    stderr.writeln('lighting io: GPU open failed: $e\n$st');
    return LightIoCore(gpuReason: '$e');
  }
}
