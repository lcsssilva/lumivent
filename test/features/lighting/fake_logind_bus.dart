part of 'logind_power_watcher_test.dart';

class _FakeLogindBus implements LogindBus {
  final sleep = StreamController<bool>(sync: true);
  final shutdown = StreamController<bool>(sync: true);
  final locks = <_FakeInhibitorLock>[];
  bool failInhibit = false;
  bool closed = false;
  bool throwOnClose = false;

  /// While set, `inhibit` does not finish (stop-during-start test).
  Completer<InhibitorLock>? holdInhibit;

  @override
  Stream<bool> get prepareForSleep => sleep.stream;
  @override
  Stream<bool> get prepareForShutdown => shutdown.stream;
  @override
  Future<InhibitorLock> inhibit() async {
    if (failInhibit) throw StateError('sem logind');
    final hold = holdInhibit;
    if (hold != null) return hold.future;
    final lock = _FakeInhibitorLock();
    locks.add(lock);
    return lock;
  }

  @override
  Future<void> close() async {
    closed = true;
    if (throwOnClose) throw StateError('close failed');
  }
}
