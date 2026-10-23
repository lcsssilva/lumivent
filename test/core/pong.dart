import 'package:lumivent/core/engine/engine_event.dart';

class Pong extends EngineEvent {
  const Pong(this.n);
  final int n;
}
