part of 'logind_power_watcher.dart';

/// Closing the fd returned by `Inhibit` releases the inhibitor in logind.
class _FdLock implements InhibitorLock {
  _FdLock(this._fd);
  final ResourceHandle _fd;

  // ResourceHandle has no close(): wrap the fd in a RandomAccessFile and close it.
  @override
  Future<void> release() async => (await _fd.toFile().close());
}
