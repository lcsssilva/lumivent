import 'dart:async';

import 'inhibitor_lock.dart';

/// Thin layer over the logind D-Bus (swapped for a fake in tests).
abstract interface class LogindBus {
  /// `PrepareForSleep(bool)`: true = going to suspend, false = resumed.
  Stream<bool> get prepareForSleep;

  /// `PrepareForShutdown(bool)`: true = going to power off/reboot.
  Stream<bool> get prepareForShutdown;

  /// `Inhibit("sleep:shutdown", ..., "delay")`; throws if logind is unavailable.
  Future<InhibitorLock> inhibit();

  Future<void> close();
}
