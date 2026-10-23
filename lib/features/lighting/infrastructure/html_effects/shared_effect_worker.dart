// One effect worker reused across effect loads.
//
// Starting a worker is expensive (in the Linux app it is a second Flutter
// engine process), and the runner loads a new runtime on every effect switch
// and on every FPS change. The worker side already replaces its QuickJS
// runtime on each `load`, so consecutive effects share one connection. Only
// the latest lease may talk to the worker; the connection closes after it has
// been idle for [SharedEffectWorker.idleTimeout], and a dead connection (a
// hung effect is killed) is replaced on the next load.

import 'dart:async';

import 'effect_worker_connection.dart';
import 'effect_script_exception.dart';

part 'effect_worker_lease.dart';

class SharedEffectWorker {
  SharedEffectWorker({
    Future<EffectWorkerConnection> Function()? spawn,
    this.idleTimeout = const Duration(seconds: 30),
  }) : _spawn = spawn ?? EffectWorkerConnection.spawn;

  final Future<EffectWorkerConnection> Function() _spawn;

  /// How long the worker stays alive with no effect loaded, so switching
  /// effects does not start a new one.
  final Duration idleTimeout;

  Future<EffectWorkerConnection>? _connection;
  EffectWorkerLease? _current;
  Timer? _idle;

  /// Hands the worker to a new effect. Earlier leases stop being current, so
  /// a runtime that is being replaced can no longer reach the worker.
  Future<EffectWorkerLease> acquire() async {
    _idle?.cancel();
    _idle = null;
    final connection = await _live();
    final lease = EffectWorkerLease._(this, connection);
    _current = lease;
    return lease;
  }

  Future<EffectWorkerConnection> _live() async {
    final pending = _connection;
    if (pending != null) {
      try {
        final connection = await pending;
        if (!connection.isClosed) return connection;
      } on Object {
        // The previous spawn failed: spawn again below.
      }
      if (identical(_connection, pending)) _connection = null;
    }
    return _connection ??= _spawn();
  }

  void _release(EffectWorkerLease lease) {
    if (!identical(_current, lease)) return;
    _current = null;
    _idle?.cancel();
    _idle = Timer(idleTimeout, _closeIdle);
  }

  void _closeIdle() {
    _idle = null;
    if (_current != null) return;
    final pending = _connection;
    _connection = null;
    unawaited(
      pending?.then(
        (connection) => connection.close(),
        onError: (Object _) {
          // A spawn that failed has nothing to close.
        },
      ),
    );
  }
}
