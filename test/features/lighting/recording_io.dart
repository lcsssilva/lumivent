import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/lighting/infrastructure/light_io_command.dart';
import 'package:lumivent/features/lighting/infrastructure/light_io_reply.dart';
import 'package:lumivent/features/lighting/infrastructure/light_io_client.dart';

/// Records the requests; answers `ok` immediately.
class RecordingIo implements LightIoClient {
  final commands = <LightIoCommand>[];
  bool disposed = false;
  @override
  Future<LightIoReply> request(LightIoCommand command) async {
    commands.add(command);
    return LightIoReply(commands.length, true, 0);
  }

  @override
  void dispose() => disposed = true;
}
