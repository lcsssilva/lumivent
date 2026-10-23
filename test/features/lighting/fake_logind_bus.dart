import 'dart:async';

import 'package:lumivent/features/lighting/infrastructure/inhibitor_lock.dart';
import 'package:lumivent/features/lighting/infrastructure/logind_bus.dart';

import 'fake_inhibitor_lock.dart';

class FakeLogindBus implements LogindBus {
  final sleep = StreamController<bool>(sync: true);
  final shutdown = StreamController<bool>(sync: true);
  final locks = <FakeInhibitorLock>[];
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
    final lock = FakeInhibitorLock();
    locks.add(lock);
    return lock;
  }

  @override
  Future<void> close() async {
    closed = true;
    if (throwOnClose) throw StateError('close failed');
  }
}
