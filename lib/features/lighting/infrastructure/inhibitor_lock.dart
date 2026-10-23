import 'dart:async';

/// Active "delay" inhibitor: releasing it allows suspend/shutdown.
abstract interface class InhibitorLock {
  Future<void> release();
}
