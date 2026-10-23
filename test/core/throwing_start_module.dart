part of 'engine_host_test.dart';

class _ThrowingStartModule implements EngineModule {
  @override
  void start(void Function(EngineEvent) emit) => throw StateError('start boom');

  @override
  bool handle(EngineCommand command) => false;

  @override
  void stop() {}
}
