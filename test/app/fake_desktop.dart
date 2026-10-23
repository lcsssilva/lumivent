import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/app/desktop/desktop_actions.dart';

class FakeDesktop implements DesktopActions {
  @override
  bool get trayAvailable => true;

  @override
  Future<void> quit() async {}
}
