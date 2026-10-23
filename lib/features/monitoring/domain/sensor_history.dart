import 'sensor_sample.dart';

/// Immutable circular history: [added] returns a new history with at most
/// [capacity] readings (5 minutes at 1 second by default).
class SensorHistory {
  const SensorHistory({
    this.capacity = defaultCapacity,
    this.samples = const [],
  });

  /// The last [capacity] readings from [samples] (oldest to newest).
  factory SensorHistory.from(
    List<SensorSample> samples, {
    int capacity = defaultCapacity,
  }) => SensorHistory(
    capacity: capacity,
    samples: List.unmodifiable(
      samples.length > capacity
          ? samples.sublist(samples.length - capacity)
          : samples,
    ),
  );

  static const defaultCapacity = 300;

  final int capacity;

  /// Oldest to newest.
  final List<SensorSample> samples;

  SensorSample? get latest => samples.lastOrNull;

  SensorHistory added(SensorSample sample) {
    final keep = samples.length >= capacity
        ? samples.sublist(samples.length - capacity + 1)
        : samples;
    return SensorHistory(
      capacity: capacity,
      samples: List.unmodifiable([...keep, sample]),
    );
  }

  /// Values for [id] in order, with `null` where there was no reading.
  List<double?> series(String id) => [for (final s in samples) s[id]];

  /// Has the metric ever been read in history?
  bool seen(String id) => samples.any((s) => s.values.containsKey(id));

  /// Is any reading of [id] above zero (fan connected)?
  bool everPositive(String id) => samples.any((s) => (s[id] ?? 0) > 0);
}
