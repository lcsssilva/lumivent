part of 'light_io_worker_test.dart';

/// Records the requests; answers `ok` immediately.
class _RecordingIo implements LightIoClient {
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
