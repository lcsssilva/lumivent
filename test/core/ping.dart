import 'package:lumivent/core/engine/engine_command.dart';

class Ping extends EngineCommand {
  const Ping(this.n);
  final int n;
}
