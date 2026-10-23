/// Fake clock: time advances only when the test commands it.
class FakeClock {
  FakeClock(this.t);
  DateTime t;

  void advance(Duration d) => t = t.add(d);
}
