import 'package:flutter_test/flutter_test.dart';

class HubWorkerClock {
  DateTime t = DateTime(2026);
  DateTime now() => t;
  void sleep(Duration d) => t = t.add(d);
  Future<void> delay(Duration d) async {
    await Future<void>.value();
    t = t.add(d);
  }
}
