import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/system/system.dart';

class FakeAutostart implements AutostartService {
  bool enabled = false;

  @override
  String get location => '/home/u/.config/systemd/user/lumivent.service';

  @override
  Future<AutostartState> status() async =>
      AutostartState(enabled: enabled, stale: false);

  @override
  Future<void> enable() async => enabled = true;

  @override
  Future<void> disable() async => enabled = false;
}
