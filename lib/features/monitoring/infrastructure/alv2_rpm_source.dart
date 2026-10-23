import 'dart:async';
import 'dart:io';

import '../../devices/devices.dart' show Alv2HubProxy;
import '../domain/metrics.dart';
import '../domain/sensor_source.dart';

/// RPM of the AL V2 hub groups as a sensor source. The protocol belongs to the
/// devices module.
///
/// The hub lives in a worker isolate, so [read] never waits for it: it returns
/// the latest reading that arrived and starts the next one (at most one in
/// flight). The value is therefore one sample period old.
///
/// [Alv2HubProxy] is shared with the fans module, but this source releases it
/// (in `dispose`). Because the engine stops modules in reverse order and fans
/// come after monitoring in the list, fans stop first and send the exit duty
/// before the hub closes.
class Alv2RpmSource implements SensorSource {
  Alv2RpmSource(this._hub, {void Function(String message)? log})
    : _log = log ?? stderr.writeln;
  final Alv2HubProxy _hub;
  final void Function(String message) _log;

  /// While the lighting streams to the hub, single RPM readings alternate
  /// between ~0.9× and ~1.12× the real speed on every group at once (the
  /// firmware's tach window is disturbed by the USB load; measured 2026-10-19:
  /// 885/1095 rpm around a steady 975). The mean of the last readings cancels it.
  static const window = 4;

  final _history = <List<int>>[];
  Map<String, double> _last = const {};
  bool _reading = false;
  bool _disposed = false;

  /// The error already logged for the current run of failures; reset by a
  /// successful read so a later failure is reported again.
  String? _loggedError;

  @override
  Map<String, double> read() {
    if (!_reading && !_disposed) {
      _reading = true;
      unawaited(_refresh());
    }
    return _last;
  }

  Future<void> _refresh() async {
    try {
      final rpm = await _hub.readRpm();
      if (rpm == null) {
        _history.clear();
        _last = const {};
        return;
      }
      _loggedError = null;
      _history.add(rpm);
      if (_history.length > window) _history.removeAt(0);
      _last = {
        for (var g = 0; g < rpm.length; g++) Metrics.alv2Rpm(g): _mean(g),
      };
    } on Object catch (e) {
      if (_loggedError != '$e') _log('monitoring: Alv2RpmSource: $e');
      _loggedError = '$e';
      _history.clear();
      _last = const {};
    } finally {
      _reading = false;
    }
  }

  /// Mean of group [g] over the history; a stopped fan (0 in the newest
  /// reading) shows 0 right away instead of decaying.
  double _mean(int g) {
    if (_history.last[g] == 0) return 0;
    final values = [for (final r in _history) r[g]];
    return (values.reduce((a, b) => a + b) / values.length).roundToDouble();
  }

  @override
  Future<void> dispose() {
    _disposed = true;
    return _hub.dispose();
  }
}
