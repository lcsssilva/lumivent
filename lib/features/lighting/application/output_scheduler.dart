import 'dart:async';

import 'lighting_messages.dart';
import 'lighting_status_reporter.dart';
import 'output_lane.dart';

/// Paces one in-flight frame per output family and chains the next due send.
class OutputScheduler {
  OutputScheduler({
    required this.now,
    required this.fps,
    required this.isActive,
    required this.canSend,
    required this.gap,
    required this.send,
    required this.status,
    required this.onError,
  });

  static const tickSlack = Duration(milliseconds: 4);

  final DateTime Function() now;
  final int Function() fps;
  final bool Function() isActive;
  final bool Function(OutputFamily family) canSend;
  final Duration Function(OutputFamily family) gap;
  final Future<bool> Function(OutputFamily family, DateTime at) send;

  /// Receives the loop start/stop and tick events for the FPS statistics.
  final LightingStatusReporter status;
  final void Function(String message) onError;

  final lanes = {
    for (final family in OutputFamily.values) family: OutputLane(),
  };
  Timer? _timer;

  bool get isRunning => _timer != null;

  void restart() {
    _timer?.cancel();
    _timer = null;
    sync();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    for (final lane in lanes.values) {
      lane.timer?.cancel();
      lane.timer = null;
    }
  }

  void sync() {
    if (!isActive()) {
      if (_timer != null) {
        _timer!.cancel();
        _timer = null;
        status.loopStopped();
      }
      return;
    }
    if (_timer != null) return;
    final at = now();
    status.loopStarted(at);
    _timer = Timer.periodic(
      Duration(microseconds: 1000000 ~/ fps()),
      (_) => _tick(),
    );
  }

  void _tick() {
    if (!isActive()) return;
    final at = now();
    try {
      status.tickStarted();
      for (final family in const [
        OutputFamily.ite,
        OutputFamily.ram,
        OutputFamily.gpu,
        OutputFamily.fans,
      ]) {
        _pump(family, fromTick: true);
      }
    } on Object catch (error) {
      onError('frame: $error');
    }
    status.updateFps(at);
  }

  void _pump(OutputFamily family, {bool fromTick = false}) {
    final lane = lanes[family]!;
    lane.timer?.cancel();
    lane.timer = null;
    if (!isActive() || !canSend(family) || !isRunning || lane.sending) return;
    final at = now();
    final minimumGap = fromTick ? gap(family) - tickSlack : gap(family);
    if (at.difference(lane.lastStart) < minimumGap) return;

    lane.sending = true;
    lane.lastStart = at;
    var sent = false;
    send(family, at)
        .then((value) => sent = value)
        .catchError((Object error) {
          onError('${family.name} frame: $error');
          return true;
        })
        .whenComplete(() {
          lane.sending = false;
          if (sent) {
            _chain(family);
          } else {
            lane.lastStart = DateTime.fromMillisecondsSinceEpoch(0);
          }
        });
  }

  void _chain(OutputFamily family) {
    if (!isActive()) return;
    final lane = lanes[family]!;
    final wait = gap(family) - now().difference(lane.lastStart);
    if (wait <= Duration.zero) {
      _pump(family);
    } else {
      lane.timer?.cancel();
      lane.timer = Timer(wait, () {
        try {
          _pump(family);
        } on Object catch (error) {
          onError('${family.name} frame: $error');
        }
      });
    }
  }
}
