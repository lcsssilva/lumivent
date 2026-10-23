import 'dart:async';
import 'dart:io';

import '../../../core/engine/engine_command.dart';
import '../../../core/engine/engine_event.dart';
import '../../../core/engine/engine_module.dart';
import '../domain/sensor_sample.dart';
import '../domain/sensor_history.dart';
import '../domain/sensor_source.dart';
import '../domain/ssd_reader.dart';
import 'request_sensor_history.dart';
import 'sensors_updated.dart';
import 'sensor_history_replay.dart';
import 'ssds_updated.dart';

/// Monitoring module part that runs in the engine: reads sensors every [period]
/// and stores 5 minutes of history (so the chart is populated when opened),
/// and reads SSD SMART data independently: every [ssdPeriod], or every
/// [ssdRetry] while an SSD lacks SMART data (a newly installed helper appears
/// without restarting the app).
class MonitoringEngineModule implements EngineModule {
  MonitoringEngineModule(
    this._openSources,
    this._openSsds, {
    this.period = const Duration(seconds: 1),
    this.ssdPeriod = const Duration(seconds: 60),
    this.ssdRetry = const Duration(seconds: 10),
  });

  /// Opens sources inside the engine isolate (FFI handles must not
  /// cross isolates).
  final List<SensorSource> Function() _openSources;
  final SsdReader Function() _openSsds;
  final Duration period;
  final Duration ssdPeriod;
  final Duration ssdRetry;

  late final List<SensorSource> _sources;
  late final SsdReader _ssds;
  late void Function(EngineEvent) _emit;
  var _history = const SensorHistory();
  Timer? _sampleTimer;
  Timer? _ssdTimer;
  final _errors = <int, String>{};
  bool _stopped = false;
  SensorSample? _latest;

  /// Latest sensor reading (`null` before the first). Other engine modules
  /// in the engine (fans) read the temperature from here.
  SensorSample? get latest => _latest;

  @override
  void start(void Function(EngineEvent) emit) {
    _emit = emit;
    _sources = _openSources();
    _ssds = _openSsds();
    _sample();
    _sampleTimer = Timer.periodic(period, (_) => _sample());
    _readSsds();
  }

  @override
  bool handle(EngineCommand command) {
    switch (command) {
      case RequestSensorHistory():
        _emit(SensorHistoryReplay(_history.samples));
      default:
        return false;
    }
    return true;
  }

  void _sample() {
    final values = <String, double>{};
    for (final (i, s) in _sources.indexed) {
      try {
        values.addAll(s.read());
        _errors.remove(i);
      } on Object catch (e) {
        // A broken source does not stop the others; report the error only once.
        if (_errors[i] != '$e') {
          stderr.writeln('monitoring: ${s.runtimeType}: $e');
        }
        _errors[i] = '$e';
      }
    }
    final sample = SensorSample(DateTime.now(), values);
    _latest = sample;
    _history = _history.added(sample);
    _emit(SensorsUpdated(sample));
  }

  /// Reads and schedules the next reading (one at a time, without overlap).
  Future<void> _readSsds() async {
    var next = ssdRetry;
    try {
      final ssds = await _ssds.read();
      if (_stopped) return;
      _emit(SsdsUpdated(ssds, DateTime.now()));
      if (ssds.every((s) => s.smart != null)) next = ssdPeriod;
    } on Object catch (e) {
      stderr.writeln('monitoring: SSDs: $e');
    }
    if (!_stopped) _ssdTimer = Timer(next, _readSsds);
  }

  @override
  Future<void> stop() async {
    _stopped = true;
    _sampleTimer?.cancel();
    _ssdTimer?.cancel();
    // Sources may release asynchronously (the AL V2 hub worker drains what the
    // fans just sent before it closes the hidraw).
    await Future.wait([
      for (final s in _sources)
        Future.sync(s.dispose).catchError(
          (Object e) => stderr.writeln('monitoring: ${s.runtimeType}: $e'),
        ),
    ]);
  }
}
