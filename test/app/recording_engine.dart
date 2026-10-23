part of 'bootstrap_test.dart';

class _RecordingEngine extends FakeEngine {
  _RecordingEngine(this.order);
  final List<String> order;

  @override
  Future<void> shutdown() async => order.add('engine');
}
