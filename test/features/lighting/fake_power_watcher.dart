import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/lighting/domain/power_watcher.dart';

class FakePowerWatcher implements PowerWatcher {
  Future<void> Function()? beforeSleep, beforeShutdown;
  void Function()? afterResume;
  bool started = false, stopped = false;
  bool failOnStart = false;

  @override
  Future<void> start({
    required Future<void> Function() beforeSleep,
    required void Function() afterResume,
    required Future<void> Function() beforeShutdown,
  }) async {
    if (failOnStart) throw StateError('no bus');
    started = true;
    this.beforeSleep = beforeSleep;
    this.afterResume = afterResume;
    this.beforeShutdown = beforeShutdown;
  }

  @override
  Future<void> stop() async => stopped = true;
}
