part of 'shared_effect_worker.dart';

/// Access to the shared worker for one loaded effect.
class EffectWorkerLease {
  EffectWorkerLease._(this._owner, this._connection);

  final SharedEffectWorker _owner;
  final EffectWorkerConnection _connection;

  /// Whether this effect is still the one loaded in a live worker.
  bool get isCurrent =>
      identical(_owner._current, this) && !_connection.isClosed;

  Future<Object?> request(List<Object?> message, {required Duration timeout}) {
    if (!isCurrent) {
      return Future.error(
        const EffectScriptException('The effect was replaced.'),
      );
    }
    return _connection.request(message, timeout: timeout);
  }

  /// Fire-and-forget; dropped once another effect took over the worker.
  void send(List<Object?> message) {
    if (isCurrent) _connection.send(message);
  }

  /// Gives the worker back. It is closed if no other effect takes it within
  /// the idle timeout.
  void release() => _owner._release(this);
}
