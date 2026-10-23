import '../../../../core/engine/engine_event.dart';

class ArgbStateChanged extends EngineEvent {
  const ArgbStateChanged(this.off);
  final bool off;
}
