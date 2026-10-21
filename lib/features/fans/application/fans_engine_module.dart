import 'dart:async';
import 'dart:io';

import '../../../core/engine/engine_host.dart';
import '../domain/fan_group.dart';
import '../domain/fan_response.dart';
import 'fans_messages.dart';

/// Fans module part that runs in the engine: every [period] it reads each
/// group's temperature source, smooths it using the group response
/// ([FanSmoother]: moving average and duty ramp), calculates curve duty, and
/// sends it to the hub. At startup it disables motherboard RPM sync because
/// the app controls the fans; if the hub rejects it, it retries on later cycles.
/// Like the vendor software, a group without a temperature is simply not updated.
class FansEngineModule implements EngineModule {
  FansEngineModule(
    this._openDriver,
    this._temps,
    FansConfig initial, {
    this.period = const Duration(seconds: 1),
    this.configDelay = const Duration(milliseconds: 100),
    this.now = DateTime.now,
  }) : _config = initial;

  /// Opens the driver inside the engine isolate.
  final FanDriver Function() _openDriver;
  final FanTemperatures _temps;
  final Duration period;

  /// Waits to combine consecutive [SetFansConfig] commands into one cycle
  /// (the editor sends one per mouse movement).
  final Duration configDelay;

  /// Smoothing clock (injectable in tests).
  final DateTime Function() now;

  FansConfig _config;
  late final FanDriver _driver;
  late void Function(EngineEvent) _emit;
  Timer? _timer;
  Timer? _configTimer;

  /// One per group: stores the average and duty ramp between cycles.
  final _smoothers = List.generate(fanGroupCount, (_) => FanSmoother());

  /// Motherboard sync was disabled successfully; do not send it again afterward.
  bool _syncOff = false;
  bool _lastHubOk = true;
  final _lastTemps = <FanTempSource, double>{};

  @override
  void start(void Function(EngineEvent) emit) {
    _emit = emit;
    _driver = _openDriver();
    unawaited(_cycle());
    _timer = Timer.periodic(period, (_) => unawaited(_cycle()));
  }

  @override
  bool handle(EngineCommand command) {
    switch (command) {
      case SetFansConfig(:final config):
        // The old source average does not apply to the new one. Changing only
        // the preset, points, or response does not reset it: the ramp prevents jumps.
        for (final g in config.groups) {
          if (g.source != _config[g.group].source) _smoothers[g.group].reset();
        }
        _config = config;
        // Combine consecutive commands: the first schedules the cycle, later ones only
        // replace the config the cycle will use.
        _configTimer ??= Timer(configDelay, () {
          _configTimer = null;
          _cycle(config: true);
        });
      default:
        return false;
    }
    return true;
  }

  /// A cycle is in flight (the hub answers asynchronously): cycles never overlap.
  bool _busy = false;

  /// A config change arrived during a cycle: run another right after it.
  bool _again = false;
  bool _stopped = false;

  Future<void> _cycle({bool config = false}) async {
    if (_stopped) return;
    if (_busy) {
      // The 1 s tick is skipped (the next one comes); a config change is not.
      if (config) _again = true;
      return;
    }
    _busy = true;
    try {
      await _run();
    } on Object catch (e) {
      stderr.writeln('fans: $e');
    } finally {
      _busy = false;
    }
    if (_again && !_stopped) {
      _again = false;
      unawaited(_cycle(config: true));
    }
  }

  // Optional per-cycle trace on stderr (LUMIVENT_FANS_TRACE=1).
  static final _trace = Platform.environment['LUMIVENT_FANS_TRACE'] == '1';

  Future<void> _run() async {
    final config = _config;
    final t = now();
    var sent = false, allOk = true;

    // Motherboard sync: disable at startup and retry until the hub accepts.
    if (!_syncOff) {
      _syncOff = await _driver.disableMotherboardSync();
      sent = true;
      allOk &= _syncOff;
      if (_stopped) return;
    }

    // Duties are queued in the hub worker in group order; the answers arrive
    // later, so the status is built once all of them are in.
    final entries = <(FanGroupConfig, double, FanStep, Future<bool>)>[];
    final status = <int, FanGroupStatus>{};
    for (final g in config.groups) {
      final raw = _temps.read(g.source);
      if (raw == null) {
        status[g.group] = FanGroupStatus(group: g.group);
        continue;
      }
      _lastTemps[g.source] = raw;
      final step = _smoothers[g.group].next(g, raw, t);
      entries.add((g, raw, step, _driver.setDuty(g.group, step.duty)));
      sent = true;
    }
    for (final (g, raw, step, result) in entries) {
      final ok = await result;
      allOk &= ok;
      if (_trace) {
        stderr.writeln(
          'fans: ${t.toIso8601String().substring(11, 23)} g${g.group} '
          'raw ${raw.toStringAsFixed(1)} avg ${step.temp.toStringAsFixed(1)} '
          'target ${step.targetRpm} duty ${step.duty} ok $ok',
        );
      }
      status[g.group] = FanGroupStatus(
        group: g.group,
        temp: step.temp,
        rawTemp: raw,
        targetRpm: step.targetRpm,
        duty: ok ? step.duty : null,
      );
    }
    if (_stopped) return;

    if (sent) _lastHubOk = allOk;
    _emit(
      FansStatus(
        [for (final g in config.groups) status[g.group]!],
        hubOk: _lastHubOk,
        syncOff: _syncOff,
      ),
    );
  }

  /// Stops the loop and leaves each group on its own curve at the last known
  /// temperature ([FanGroupConfig.exitDuty]). Runs before monitoring releases
  /// the hub (the engine stops in reverse order).
  @override
  Future<void> stop() async {
    _stopped = true;
    _timer?.cancel();
    _configTimer?.cancel();
    _configTimer = null;
    // Sent after anything a cycle already queued, so the hub worker applies
    // them last; the caller (monitoring) closes the hub only after this.
    final results = [
      for (final g in _config.groups)
        _driver.setDuty(
          g.group,
          g.exitDuty(_temps.read(g.source) ?? _lastTemps[g.source]),
        ),
    ];
    try {
      await Future.wait(results).timeout(exitDutyTimeout);
    } on Object catch (e) {
      stderr.writeln('fans: exit duty: $e');
    }
  }

  /// Longest [stop] waits for the hub to confirm the exit duty.
  static const exitDutyTimeout = Duration(milliseconds: 600);
}
