import 'dart:isolate';

import 'engine_module.dart';

/// Builds modules inside the engine isolate. Must be a top-level or static
/// function so it can be sent to the isolate.
typedef EngineModulesFactory<T> = List<EngineModule> Function(T init);

class EngineBootstrap<T> {
  const EngineBootstrap(this.events, this.factory, this.init);
  final SendPort events;
  final EngineModulesFactory<T> factory;
  final T init;

  List<EngineModule> build() => factory(init);
}
