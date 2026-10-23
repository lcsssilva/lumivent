part of 'logind_power_watcher_test.dart';

class _FakeInhibitorLock implements InhibitorLock {
  bool released = false;
  bool throwOnRelease = false;
  @override
  Future<void> release() async {
    released = true;
    if (throwOnRelease) throw StateError('release failed');
  }
}
