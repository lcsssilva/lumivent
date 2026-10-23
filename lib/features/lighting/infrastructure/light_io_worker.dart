import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import '../../devices/devices.dart';
import '../domain/lighting_config.dart';

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
// its own worker (`hub_worker.dart`).

// ── Protocol ───────────────────────────────────────────────────────────────

/// Command for the worker. Every field is sendable between isolates.
sealed class LightIoCommand {
  const LightIoCommand();
}

/// Skipped (`ok == false`, `dropped`) if a priority command arrived after it
/// and before it started.
sealed class DroppableIoCommand extends LightIoCommand {
  const DroppableIoCommand();
}

/// A priority command discards the droppable ones still waiting.
sealed class PriorityIoCommand extends LightIoCommand {
  const PriorityIoCommand();
}

class IoInitBoard extends LightIoCommand {
  const IoInitBoard();
}

/// D_LED1 case strip: [rgb] are 47 x 3 bytes.
class IoChassis extends DroppableIoCommand {
  const IoChassis(this.rgb);
  final Uint8List rgb;
}

/// Board zone colors in `boardZoneIds` order, 3 bytes each.
class IoBoardColors extends DroppableIoCommand {
  const IoBoardColors(this.rgb);
  final Uint8List rgb;
}

/// Hardware effects of several zones (keys `0x20`/`0x22`/`0x23`) in one batch.
class IoZoneEffects extends LightIoCommand {
  const IoZoneEffects(this.zones);
  final Map<int, BoardZoneConfig> zones;
}

class IoBoardOff extends PriorityIoCommand {
  const IoBoardOff();
}

/// 12 LEDs of a stick: [rgb] are 36 bytes.
class IoRam extends DroppableIoCommand {
  const IoRam(this.slot, this.rgb);
  final int slot;
  final Uint8List rgb;
}

class IoRamOff extends PriorityIoCommand {
  const IoRamOff();
}

/// Reads firmware and SSID of the GPU (required before effects).
class IoInitGpu extends LightIoCommand {
  const IoInitGpu();
}

/// Fixed-color mode of the GPU: Static with the global brightness byte.
class IoGpuStatic extends DroppableIoCommand {
  const IoGpuStatic(this.r, this.g, this.b, this.brightness);
  final int r, g, b, brightness;
}

/// GPU firmware effect (hardware mode).
class IoGpuEffect extends LightIoCommand {
  const IoGpuEffect(this.config);
  final GpuHardwareConfig config;
}

class IoGpuOff extends PriorityIoCommand {
  const IoGpuOff();
}

class IoInvalidate extends LightIoCommand {
  const IoInvalidate();
}

/// Closes the drivers this worker owns; nothing runs after it.
class IoClose extends PriorityIoCommand {
  const IoClose();
}

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

class LightIoRequest {
  const LightIoRequest(this.id, this.command);
  final int id;
  final LightIoCommand command;
}

class LightIoReply {
  const LightIoReply(
    this.id,
    this.ok,
    this.micros, {
    this.dropped = false,
    this.ramReasons,
    this.gpuReason,
  });

  /// Reply for a command that could not reach the worker.
  const LightIoReply.failed(this.id)
    : ok = false,
      micros = 0,
      dropped = false,
      ramReasons = null,
      gpuReason = null;

  final int id;
  final bool ok;

  /// Time the worker spent running the command.
  final int micros;

  /// Discarded before running because a priority command overtook it.
  final bool dropped;

  /// Why each Fury slot is disabled (`null` = usable), set on RAM replies.
  final List<String?>? ramReasons;

  /// Why the GPU is disabled (`null` = usable), set on GPU replies.
  final String? gpuReason;
}

// ── Worker logic (no isolate: tests drive it directly) ─────────────────────

/// Runs the commands over the drivers, strictly in arrival order.
class LightIoCore {
  /// A driver left `null` belongs to another worker: its commands fail.
  /// [gpuReason] is the open failure when the controller itself is absent.
  LightIoCore({this._ite, this._fury, this._gpu, this.gpuReason});

  final IteController? _ite;
  final FuryController? _fury;
  final GpuController? _gpu;

  /// Last GPU failure reported inside the worker (also sent in replies).
  String? gpuReason;

  Future<void> _chain = Future<void>.value();

  /// Bumped on every priority command: droppable ones captured an older value.
  int _epoch = 0;
  bool _closed = false;

  /// Queues [command] and returns its reply. Never throws.
  Future<LightIoReply> handle(int id, LightIoCommand command) {
    if (command is PriorityIoCommand) _epoch++;
    final epoch = _epoch;
    final reply = _chain.then((_) async {
      if (command is DroppableIoCommand && epoch != _epoch) {
        return LightIoReply(id, false, 0, dropped: true);
      }
      final watch = Stopwatch()..start();
      final ok = await _run(command);
      return LightIoReply(
        id,
        ok,
        watch.elapsedMicroseconds,
        ramReasons: reportsRamReasons(command) ? _reasons() : null,
        gpuReason: reportsGpuReason(command)
            ? _gpu?.disabledReason ?? gpuReason
            : null,
      );
    });
    _chain = reply.then((_) {}, onError: (Object _) {});
    return reply.catchError((Object _) => LightIoReply.failed(id));
  }

  List<String?> _reasons() => [
    _fury?.disabledReason(0),
    _fury?.disabledReason(1),
  ];

  Future<bool> _run(LightIoCommand c) async {
    if (_closed) return false;
    final ite = _ite, fury = _fury, gpu = _gpu;
    try {
      switch (c) {
        case IoInitBoard():
          return ite?.init() ?? false;
        case IoChassis(:final rgb):
          return ite?.streamCase(rgb) ?? false;
        case IoBoardColors(:final rgb):
          if (ite == null) return false;
          return ite.setZoneColors({
            for (final (i, z) in boardZoneIds.indexed)
              z: (rgb[3 * i], rgb[3 * i + 1], rgb[3 * i + 2]),
          });
        case IoZoneEffects(:final zones):
          if (ite == null) return false;
          return await ite.setZoneEffects({
            for (final MapEntry(key: zone, value: config) in zones.entries)
              zone - iteZoneIoShield1: IteHardwareEffect(
                _iteMode(config.mode),
                color: (config.color.r, config.color.g, config.color.b),
                speed: config.speed,
                brightness: config.brightness,
              ),
          });
        case IoBoardOff():
          return ite?.allOff() ?? false;
        case IoRam(:final slot, :final rgb):
          return fury?.setColors(slot, rgb) ?? false;
        case IoRamOff():
          if (fury == null) return false;
          var ok = true;
          for (final slot in fury.activeSlots) {
            ok &= fury.setSingleColor(slot, 0, 0, 0);
          }
          return ok;
        case IoInitGpu():
          if (gpu == null) return false;
          final ok = gpu.init();
          gpuReason = gpu.disabledReason;
          return ok;
        case IoGpuStatic(:final r, :final g, :final b, :final brightness):
          if (gpu == null) return false;
          final ok = gpu.sendEffect(
            effect: GpuEffectCode.staticColor,
            speed: 0,
            brightness: brightness,
            color: GpuRgb(r, g, b),
          );
          gpuReason = gpu.disabledReason;
          return ok;
        case IoGpuEffect(:final config):
          if (gpu == null) return false;
          final effect = GpuEffectCode.byName(config.effect.name);
          if (effect == null) return false;
          // Off does not need speed/brightness/palette; force them to zero so
          // the packet is the same one used by "turn all ARGB off".
          final off = effect == GpuEffectCode.off;
          final ok = gpu.sendEffect(
            effect: effect,
            speed: off ? 0 : config.speed,
            brightness: off ? 0 : config.brightness,
            color: off
                ? GpuRgb.black
                : GpuRgb(config.color.r, config.color.g, config.color.b),
            colors: off
                ? const []
                : [for (final c in config.colors) GpuRgb(c.r, c.g, c.b)],
          );
          gpuReason = gpu.disabledReason;
          return ok;
        case IoGpuOff():
          if (gpu == null) return false;
          final ok = gpu.turnOff();
          gpuReason = gpu.disabledReason;
          return ok;
        case IoInvalidate():
          fury?.invalidate();
          gpu?.invalidate();
          return true;
        case IoClose():
          _closed = true;
          _closeDrivers();
          return true;
      }
    } on Object catch (e, st) {
      // Driver exceptions (safety guards, bus errors) become "unavailable".
      stderr.writeln('lighting io: $e\n$st');
      return false;
    }
  }

  void _closeDrivers() {
    try {
      _ite?.dispose();
    } on Object catch (e, st) {
      stderr.writeln('lighting: ITE close: $e\n$st');
    }
    try {
      _fury?.close();
    } on Object catch (e, st) {
      stderr.writeln('lighting: Fury close: $e\n$st');
    }
    try {
      _gpu?.close();
    } on Object catch (e, st) {
      stderr.writeln('lighting: GPU close: $e\n$st');
    }
  }

  static IteHardwareMode _iteMode(BoardEffectMode m) => switch (m) {
    BoardEffectMode.static => IteHardwareMode.staticColor,
    BoardEffectMode.pulse => IteHardwareMode.pulse,
    BoardEffectMode.flash => IteHardwareMode.flash,
    BoardEffectMode.doubleFlash => IteHardwareMode.doubleFlash,
    BoardEffectMode.colorCycle => IteHardwareMode.colorCycle,
    BoardEffectMode.wave => IteHardwareMode.wave,
  };
}

/// Which drivers an [IsolateLightIo] worker owns.
enum LightIoKind { board, ram, gpu }

// ── Clients ────────────────────────────────────────────────────────────────

/// How the adapter reaches the worker.
abstract interface class LightIoClient {
  /// Never throws: a worker that is gone answers `ok == false`.
  Future<LightIoReply> request(LightIoCommand command);

  /// Releases the isolate/port. [IoClose] must have been requested before for
  /// an orderly driver shutdown.
  void dispose();
}

/// Same-isolate client over a [LightIoCore] (tests; no isolate).
class LocalLightIo implements LightIoClient {
  LocalLightIo(this.core);
  final LightIoCore core;
  int _next = 0;

  @override
  Future<LightIoReply> request(LightIoCommand command) =>
      core.handle(_next++, command);

  @override
  void dispose() {}
}

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
