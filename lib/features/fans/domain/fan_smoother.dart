import 'fan_curve.dart';
import 'fan_group_config.dart';
import 'fan_response.dart';
import 'fan_step.dart';

/// Group smoothing state: moving temperature average over the response window
/// and asymmetric duty ramp (increases quickly, decreases slowly).
class FanSmoother {
  final _samples = <(DateTime, double)>[];

  /// Current level in % (0 = stopped).
  double? _level;
  DateTime? _at;

  /// Loop step: [temp] is the group's raw source reading at [now].
  FanStep next(FanGroupConfig group, double temp, DateTime now) {
    final avg = _average(temp, now, group.response.window);
    final rpm = group.targetRpm(avg);
    return FanStep(
      temp: avg,
      targetRpm: rpm,
      duty: _ramp(dutyFor(rpm, group.size), now, group.response),
    );
  }

  /// Forgets history (for example, after changing the temperature source).
  void reset() {
    _samples.clear();
    _level = null;
    _at = null;
  }

  /// Samples closer than this are one reading: extra cycles (config changes,
  /// timers catching up after a stall) must not weigh more in the average.
  static const _minSampleGap = Duration(milliseconds: 500);

  /// The average always keeps this many latest samples, even if older than the
  /// window. When cycles are delayed (a saturated engine) a pure time window
  /// would shrink to one sample and pass every Tctl spike straight through.
  static const _minSamples = 3;

  double _average(double temp, DateTime now, Duration window) {
    if (_samples.isNotEmpty &&
        now.difference(_samples.last.$1) < _minSampleGap) {
      _samples.removeLast();
    }
    _samples.add((now, temp));
    if (window == Duration.zero) {
      _samples.removeRange(0, _samples.length - 1);
    } else {
      while (_samples.length > _minSamples &&
          now.difference(_samples.first.$1) >= window) {
        _samples.removeAt(0);
      }
    }
    return _samples.fold(0.0, (sum, s) => sum + s.$2) / _samples.length;
  }

  int _ramp(int target, DateTime now, FanResponse r) {
    final want = target <= 1 ? 0.0 : target.toDouble();
    final prev = _level, prevAt = _at;
    _at = now;
    var level = want;
    if (prev != null && prevAt != null && r != FanResponse.fast) {
      // Limit the step by elapsed real time (extra cycles occur when config
      // changes); a long interval (delayed cycle) must not become a big jump:
      // two periods at most.
      final dt = (now.difference(prevAt).inMicroseconds / 1e6).clamp(0.0, 2.0);
      level = prev + (want - prev).clamp(-r.rampDown * dt, r.rampUp * dt);
    }
    _level = level;
    if (level <= 0) return 1;
    return level.round().clamp(10, 100);
  }
}
