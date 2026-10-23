import 'dart:async';

import 'light_io_command.dart';
import 'light_io_reply.dart';

/// How the adapter reaches the worker.
abstract interface class LightIoClient {
  /// Never throws: a worker that is gone answers `ok == false`.
  Future<LightIoReply> request(LightIoCommand command);

  /// Releases the isolate/port. [IoClose] must have been requested before for
  /// an orderly driver shutdown.
  void dispose();
}
