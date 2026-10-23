import 'dart:async';

/// Port: a sensor source (sysfs, AL V2 hub…). Runs in the engine.
abstract interface class SensorSource {
  /// Current reading. May return fewer metrics if something disappears.
  Map<String, double> read();

  /// Releases the source. May be asynchronous (a source backed by a worker
  /// isolate); the engine waits for it before it reports it has stopped.
  FutureOr<void> dispose();
}
