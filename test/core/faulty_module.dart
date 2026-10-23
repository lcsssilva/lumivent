part of 'engine_host_test.dart';

/// Throws on [Boom] in handle, and/or in stop when [throwOnStop] is set.
class _FaultyModule implements EngineModule {
  _FaultyModule({this.throwOnStop = false});
  final bool throwOnStop;

  @override
  void start(void Function(EngineEvent) emit) {}

  @override
  bool handle(EngineCommand command) {
    if (command is! Boom) return false;
    throw StateError('handle boom');
  }

  @override
  void stop() {
    if (throwOnStop) throw StateError('stop boom');
  }
}
