import 'package:lumivent/features/monitoring/monitoring.dart';

class FakeSource implements SensorSource {
  int reads = 0;
  bool disposed = false;
  bool fail = false;

  @override
  Map<String, double> read() {
    if (fail) throw StateError('sumiu');
    return {'x': (++reads).toDouble()};
  }

  @override
  void dispose() => disposed = true;
}
