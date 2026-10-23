part of 'isolate_engine.dart';

class _EngineBootstrap<T> {
  const _EngineBootstrap(this.events, this.factory, this.init);
  final SendPort events;
  final EngineModulesFactory<T> factory;
  final T init;

  List<EngineModule> build() => factory(init);
}
