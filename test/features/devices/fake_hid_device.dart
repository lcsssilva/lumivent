import 'dart:typed_data';

import 'package:lumivent/core/platform/hid_api.dart';

class FakeHidDevice implements HidDevice {
  @override
  void sendFeature(List<int> data, int length) {}
  @override
  Uint8List getInput(int reportId, int length) => Uint8List(length);
  @override
  void close() {}
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
