import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'hub.dart';
import 'protocol.dart';

// AL V2 hub worker.
//
// Every `hid_write`/feature report blocks its thread for the USB transfer
// (~3-7 ms, ~12 packets per lighting frame). Done in the engine isolate, that
// starves the tick loops, so the real [Alv2Hub] (queue, quiet times, priority
// epochs, packet guard) lives in its own isolate and the engine talks to it
// through [Alv2HubProxy]. Packet order and pauses are still decided by a single
// owner: the hub inside the worker.

// ── Protocol ───────────────────────────────────────────────────────────────

/// Command for the worker. Every field is sendable between isolates.
sealed class Alv2HubCommand {
  const Alv2HubCommand();
}

class HubReadRpm extends Alv2HubCommand {
  const HubReadRpm();
}

class HubSetDuty extends Alv2HubCommand {
  const HubSetDuty(this.group, this.duty);
  final int group, duty;
}

class HubSetMotherboardSync extends Alv2HubCommand {
  const HubSetMotherboardSync(this.sync);
  final List<bool> sync;
}

class HubSetQuantity extends Alv2HubCommand {
  const HubSetQuantity(this.group, this.quantity);
  final int group, quantity;
}

class HubSetMergeOrder extends Alv2HubCommand {
  const HubSetMergeOrder(this.order);
  final List<int> order;
}

class HubDisableArgbSync extends Alv2HubCommand {
  const HubDisableArgbSync();
}

class HubSendLighting extends Alv2HubCommand {
  const HubSendLighting(
    this.writes, {
    this.frame = true,
    this.priority = false,
  });
  final List<Alv2PortWrite> writes;
  final bool frame, priority;
}

class HubStreamCanvas extends Alv2HubCommand {
  const HubStreamCanvas(this.writes);
  final List<Alv2PortWrite> writes;
}

class HubIdentify extends Alv2HubCommand {
  const HubIdentify(this.group, {this.merge = false});
  final int group;
  final bool merge;
}

/// Closes the hub inside the worker; everything sent before it has already
/// reached the device (or been dropped by the hub rules).
class HubDispose extends Alv2HubCommand {
  const HubDispose();
}

class Alv2HubRequest {
  const Alv2HubRequest(this.id, this.command);
  final int id;
  final Alv2HubCommand command;
}

class Alv2HubReply {
  const Alv2HubReply(this.id, {this.ok = false, this.rpm});

  /// Reply for a command that could not reach the worker.
  const Alv2HubReply.failed(this.id) : ok = false, rpm = null;

  final int id;
  final bool ok;

  /// Set on [HubReadRpm] replies.
  final List<int>? rpm;
}

// ── Worker logic (no isolate: tests drive it directly) ─────────────────────

/// Runs commands over an [Alv2Hub]. It does **not** serialize them: the hub
/// already owns the queue, the pauses and the priority rules, and the
/// synchronous operations (duty, RPM) deliberately run during an asynchronous
/// frame, as they did when the hub lived in the engine isolate.
class Alv2HubCore {
  Alv2HubCore(this._hub);
  final Alv2Hub _hub;

  /// Starts [command] now and answers when it finishes. Never throws.
  Future<Alv2HubReply> handle(int id, Alv2HubCommand command) async {
    try {
      return switch (command) {
        HubReadRpm() => _rpm(id, _hub.readRpm()),
        HubSetDuty(:final group, :final duty) => _ok(
          id,
          _hub.setDuty(group, duty),
        ),
        HubSetMotherboardSync(:final sync) => _ok(
          id,
          _hub.setMotherboardSync(sync),
        ),
        HubSetQuantity(:final group, :final quantity) => _ok(
          id,
          _hub.setQuantity(group, quantity),
        ),
        HubSetMergeOrder(:final order) => _ok(id, _hub.setMergeOrder(order)),
        HubDisableArgbSync() => _ok(id, _hub.disableArgbSync()),
        HubSendLighting(:final writes, :final frame, :final priority) => _ok(
          id,
          await _hub.sendLighting(writes, frame: frame, priority: priority),
        ),
        HubStreamCanvas(:final writes) => _ok(
          id,
          await _hub.streamCanvas(writes),
        ),
        HubIdentify(:final group, :final merge) => _ok(
          id,
          await _hub.identify(group, merge: merge),
        ),
        HubDispose() => _dispose(id),
      };
    } on Object catch (e) {
      // Safety guards and unexpected driver errors become "unavailable".
      stderr.writeln('alv2 hub: $e');
      return Alv2HubReply.failed(id);
    }
  }

  static Alv2HubReply _ok(int id, bool ok) => Alv2HubReply(id, ok: ok);
  static Alv2HubReply _rpm(int id, List<int>? rpm) =>
      Alv2HubReply(id, ok: rpm != null, rpm: rpm);

  Alv2HubReply _dispose(int id) {
    _hub.dispose();
    return Alv2HubReply(id, ok: true);
  }
}

// ── Links ──────────────────────────────────────────────────────────────────

/// How the proxy reaches the worker.
abstract interface class Alv2HubLink {
  /// Never throws: a worker that is gone answers [Alv2HubReply.failed].
  Future<Alv2HubReply> request(Alv2HubCommand command);

  /// Releases the isolate/port ([HubDispose] must have been requested first
  /// for an orderly shutdown).
  void dispose();
}

/// Same-isolate link over an [Alv2HubCore] (tests; no isolate).
class LocalAlv2HubLink implements Alv2HubLink {
  LocalAlv2HubLink(this.core);
  final Alv2HubCore core;
  int _next = 0;

  @override
  Future<Alv2HubReply> request(Alv2HubCommand command) =>
      core.handle(_next++, command);

  @override
  void dispose() {}
}

/// Link to the real worker isolate, spawned lazily by the constructor (the
/// requests wait for it). Create it inside the engine isolate.
class IsolateAlv2HubLink implements Alv2HubLink {
  IsolateAlv2HubLink() {
    _port = _start();
  }

  final _rx = ReceivePort('lumivent-alv2-hub-replies');
  final _pending = <int, Completer<Alv2HubReply>>{};
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
        case Alv2HubReply():
          _pending.remove(m.id)?.complete(m);
        case null:
          // The worker exited: nobody will answer what is still pending.
          if (!first.isCompleted) first.complete(null);
          _failPending();
      }
    });
    try {
      _isolate = await Isolate.spawn(
        _hubWorkerMain,
        _rx.sendPort,
        debugName: 'lumivent-alv2-hub',
        onExit: _rx.sendPort,
      );
      if (_disposed) _isolate?.kill(priority: Isolate.immediate);
    } on Object catch (e) {
      stderr.writeln('alv2 hub: spawn failed: $e');
      if (!first.isCompleted) first.complete(null);
    }
    return first.future;
  }

  @override
  Future<Alv2HubReply> request(Alv2HubCommand command) async {
    final id = _next++;
    final done = Completer<Alv2HubReply>();
    _pending[id] = done;
    // Awaiting the same future keeps the callers' order.
    final port = await _port;
    if (port == null || _disposed) {
      _pending.remove(id);
      return Alv2HubReply.failed(id);
    }
    port.send(Alv2HubRequest(id, command));
    return done.future;
  }

  void _failPending() {
    for (final e in _pending.entries.toList()) {
      e.value.complete(Alv2HubReply.failed(e.key));
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

/// Worker entry point: the only place where the hidraw is opened.
Future<void> _hubWorkerMain(SendPort toEngine) async {
  final rx = ReceivePort('lumivent-alv2-hub');
  final core = Alv2HubCore(Alv2Hub.open());
  toEngine.send(rx.sendPort);
  await for (final m in rx) {
    if (m is! Alv2HubRequest) continue;
    // Not awaited: the hub decides ordering, and a long operation (identify)
    // must not hold back priority sends or duty writes.
    final reply = core.handle(m.id, m.command);
    unawaited(reply.then(toEngine.send));
    if (m.command is HubDispose) {
      await reply;
      rx.close();
    }
  }
}

// ── Proxy ──────────────────────────────────────────────────────────────────

/// Asynchronous face of the hub for the engine isolate. Same semantics as
/// [Alv2Hub], with every call answered by the worker.
///
/// One instance is created by the engine composition and shared by monitoring
/// (RPM), fans (duty), and lighting (frames). Only the monitoring source
/// releases it, and the engine stops modules in reverse order, so lighting and
/// fans stop before the hub closes. Calls never throw: an unavailable worker
/// answers `false` (or a `null` RPM); driver and spawn errors go to stderr.
class Alv2HubProxy {
  Alv2HubProxy(this._link);

  /// Spawns the worker isolate. Call inside the engine isolate.
  factory Alv2HubProxy.open() => Alv2HubProxy(IsolateAlv2HubLink());

  /// Proxy over a hub in this isolate (tests; no isolate).
  factory Alv2HubProxy.local(Alv2Hub hub) =>
      Alv2HubProxy(LocalAlv2HubLink(Alv2HubCore(hub)));

  /// How long [dispose] waits for the worker before killing it.
  static const closeTimeout = Duration(seconds: 1);

  final Alv2HubLink _link;
  Future<void>? _disposing;

  bool get _closed => _disposing != null;

  /// RPM for the 4 groups, or `null` if the hub is inaccessible.
  Future<List<int>?> readRpm() async =>
      _closed ? null : (await _link.request(const HubReadRpm())).rpm;

  Future<bool> setDuty(int group, int duty) => _ok(HubSetDuty(group, duty));

  Future<bool> setMotherboardSync(List<bool> sync) =>
      _ok(HubSetMotherboardSync(List.of(sync)));

  Future<bool> setQuantity(int group, int q) => _ok(HubSetQuantity(group, q));

  Future<bool> setMergeOrder(List<int> order) =>
      _ok(HubSetMergeOrder(List.of(order)));

  Future<bool> disableArgbSync() => _ok(const HubDisableArgbSync());

  /// See [Alv2Hub.sendLighting]; [priority] skips the worker's queue.
  Future<bool> sendLighting(
    List<Alv2PortWrite> writes, {
    bool frame = true,
    bool priority = false,
  }) => _ok(HubSendLighting(List.of(writes), frame: frame, priority: priority));

  Future<bool> streamCanvas(List<Alv2PortWrite> writes) =>
      _ok(HubStreamCanvas(List.of(writes)));

  Future<bool> identify(int group, {bool merge = false}) =>
      _ok(HubIdentify(group, merge: merge));

  /// Closes the hub after everything already sent to it, then releases the
  /// worker; after [closeTimeout] the worker is killed. Safe to call twice.
  Future<void> dispose() => _disposing ??= _dispose();

  Future<void> _dispose() async {
    try {
      await _link
          .request(const HubDispose())
          .timeout(
            closeTimeout,
            onTimeout: () => const Alv2HubReply.failed(-1),
          );
    } finally {
      _link.dispose();
    }
  }

  Future<bool> _ok(Alv2HubCommand c) async =>
      _closed ? false : (await _link.request(c)).ok;
}
