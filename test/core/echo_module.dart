part of 'engine_host_test.dart';

class _EchoModule implements EngineModule {
  _EchoModule(this.base);
  final int base;
  late void Function(EngineEvent) emit;

  @override
  void start(void Function(EngineEvent) emit) =>
      (this.emit = emit)(Started(base));

  @override
  bool handle(EngineCommand command) {
    if (command is! Ping) return false;
    emit(Pong(command.n + base));
    return true;
  }

  @override
  void stop() => emit(const Stopping());
}
