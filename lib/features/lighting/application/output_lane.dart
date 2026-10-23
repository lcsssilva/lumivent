import 'dart:async';

/// Frame-in-flight state and counters for one family.
class OutputLane {
  bool sending = false;
  DateTime lastStart = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? timer;
  int frames = 0;
  int sendUs = 0;

  void record(Duration took) => sendUs += took.inMicroseconds;
  void countFrame() => frames++;

  void resetStats() {
    frames = 0;
    sendUs = 0;
  }
}
