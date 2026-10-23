import 'dart:async';

import 'light_io_command.dart';
import 'light_io_reply.dart';
import 'light_io_core.dart';
import 'light_io_client.dart';

/// Same-isolate client over a [LightIoCore] (tests; no isolate).
class LocalLightIo implements LightIoClient {
  LocalLightIo(this.core);
  final LightIoCore core;
  int _next = 0;

  @override
  Future<LightIoReply> request(LightIoCommand command) =>
      core.handle(_next++, command);

  @override
  void dispose() {}
}
