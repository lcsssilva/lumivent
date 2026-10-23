class FakeStopwatch implements Stopwatch {
  @override
  Duration elapsed = Duration.zero;

  @override
  void start() {}

  @override
  void stop() {}

  @override
  void reset() => elapsed = Duration.zero;

  @override
  int get elapsedMicroseconds => elapsed.inMicroseconds;

  @override
  int get elapsedMilliseconds => elapsed.inMilliseconds;

  @override
  int get elapsedTicks => elapsed.inMicroseconds;

  @override
  int get frequency => 1000000;

  @override
  bool get isRunning => true;
}
