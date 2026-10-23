import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/lighting/infrastructure/inhibitor_lock.dart';

class FakeInhibitorLock implements InhibitorLock {
  bool released = false;
  bool throwOnRelease = false;
  @override
  Future<void> release() async {
    released = true;
    if (throwOnRelease) throw StateError('release failed');
  }
}
