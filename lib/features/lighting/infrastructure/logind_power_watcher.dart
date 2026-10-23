import 'dart:async';
import 'dart:io';

import 'package:dbus/dbus.dart';

import '../domain/power_watcher.dart';
import 'inhibitor_lock.dart';
import 'logind_bus.dart';

part 'fd_lock.dart';
part 'dbus_logind_bus.dart';

/// Inhibitor/state logic over a [LogindBus]. Signals are handled one at a time
/// in a queue; repeated signals (true, true) are ignored.
class LogindPowerWatcher implements PowerWatcher {
  LogindPowerWatcher({
    LogindBus Function()? busFactory,
    this.callbackTimeout = const Duration(seconds: 3),
  }) : _busFactory = busFactory ?? DBusLogindBus.new;

  final LogindBus Function() _busFactory;

  /// Maximum time for each callback; logind `InhibitDelayMaxSec` is 5 seconds.
  final Duration callbackTimeout;

  LogindBus? _bus;
  InhibitorLock? _lock;
  final _subs = <StreamSubscription<bool>>[];
  Future<void> _queue = Future.value();
  bool _started = false;
  bool _sleeping = false;
  bool _shuttingDown = false;

  late Future<void> Function() _beforeSleep;
  late void Function() _afterResume;
  late Future<void> Function() _beforeShutdown;

  /// Whether an inhibitor is active (for tests/diagnostics).
  bool get hasInhibitor => _lock != null;

  @override
  Future<void> start({
    required Future<void> Function() beforeSleep,
    required void Function() afterResume,
    required Future<void> Function() beforeShutdown,
  }) async {
    if (_started) return;
    _started = true;
    _beforeSleep = beforeSleep;
    _afterResume = afterResume;
    _beforeShutdown = beforeShutdown;
    try {
      final bus = _bus = _busFactory();
      _subs
        ..add(
          bus.prepareForSleep.listen(
            (v) => _enqueue(() => _onSleep(v)),
            onError: _log,
          ),
        )
        ..add(
          bus.prepareForShutdown.listen(
            (v) => _enqueue(() => _onShutdown(v)),
            onError: _log,
          ),
        );
    } catch (e) {
      _log('system bus/logind unavailable: $e');
      return;
    }
    await _acquire();
  }

  @override
  Future<void> stop() async {
    if (!_started) return;
    _started = false;
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    await _queue;
    await _release();
    final bus = _bus;
    _bus = null;
    try {
      await bus?.close();
    } catch (e) {
      _log('failed to close bus: $e');
    }
  }

  void _enqueue(Future<void> Function() job) {
    _queue = _queue.then((_) => job()).catchError((Object e) => _log('$e'));
  }

  Future<void> _onSleep(bool going) async {
    if (going) {
      if (_sleeping) return;
      _sleeping = true;
      await _run(_beforeSleep);
      await _release();
    } else {
      if (!_sleeping) return;
      _sleeping = false;
      try {
        _afterResume();
      } catch (e) {
        _log('afterResume: $e');
      }
      await _acquire();
    }
  }

  Future<void> _onShutdown(bool going) async {
    if (going) {
      if (_shuttingDown) return;
      _shuttingDown = true;
      await _run(_beforeShutdown);
      await _release();
    } else {
      // Shutdown cancelled: the LEDs were turned off, bring them back and take
      // a new inhibitor for the next suspend/shutdown.
      if (!_shuttingDown) return;
      _shuttingDown = false;
      try {
        _afterResume();
      } catch (e) {
        _log('afterResume: $e');
      }
      await _acquire();
    }
  }

  Future<void> _run(Future<void> Function() cb) async {
    try {
      await cb().timeout(callbackTimeout);
    } on TimeoutException {
      _log('callback exceeded ${callbackTimeout.inMilliseconds} ms');
    } catch (e) {
      _log('callback: $e');
    }
  }

  Future<void> _acquire() async {
    final bus = _bus;
    if (bus == null || _lock != null || _shuttingDown) return;
    try {
      final lock = await bus.inhibit();
      if (!_started || _lock != null) {
        await lock.release();
      } else {
        _lock = lock;
      }
    } catch (e) {
      _log('Inhibit failed (continuing without inhibitor): $e');
    }
  }

  Future<void> _release() async {
    final lock = _lock;
    _lock = null;
    if (lock == null) return;
    try {
      await lock.release();
    } catch (e) {
      _log('failed to release inhibitor: $e');
    }
  }

  static void _log(Object e) => stderr.writeln('[power] $e');
}
