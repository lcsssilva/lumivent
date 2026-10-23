import 'package:flutter_test/flutter_test.dart';

import '../fake_engine.dart';

class RecordingEngine extends FakeEngine {
  RecordingEngine(this.order);
  final List<String> order;

  @override
  Future<void> shutdown() async => order.add('engine');
}
