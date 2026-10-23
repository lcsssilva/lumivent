import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'alv2_hub.dart';
import 'alv2_hub_command.dart';
import 'alv2_hub_request.dart';
import 'alv2_hub_reply.dart';
import 'alv2_hub_core.dart';
import 'alv2_hub_link.dart';

// AL V2 hub worker.
//
// Every `hid_write`/feature report blocks its thread for the USB transfer
// (~3-7 ms, ~12 packets per lighting frame). Done in the engine isolate, that
// starves the tick loops, so the real [Alv2Hub] (queue, quiet times, priority
// epochs, packet guard) lives in its own isolate and the engine talks to it
// through [Alv2HubProxy]. Packet order and pauses are still decided by a single
// owner: the hub inside the worker.

// ── Links ──────────────────────────────────────────────────────────────────

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
