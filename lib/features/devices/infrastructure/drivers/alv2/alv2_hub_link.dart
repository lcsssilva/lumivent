import 'dart:async';

import 'alv2_hub_command.dart';
import 'alv2_hub_reply.dart';

/// How the proxy reaches the worker.
abstract interface class Alv2HubLink {
  /// Never throws: a worker that is gone answers [Alv2HubReply.failed].
  Future<Alv2HubReply> request(Alv2HubCommand command);

  /// Releases the isolate/port ([HubDispose] must have been requested first
  /// for an orderly shutdown).
  void dispose();
}
