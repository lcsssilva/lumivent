import 'dart:typed_data';

import 'package:lumivent/core/platform/hid_exception.dart';
import 'package:lumivent/features/devices/infrastructure/drivers/ite5702/ite_transport.dart';

import 'ite_lighting_test.dart';

class FakeIte implements IteTransport {
  final sent = <List<int>>[];
  bool failNext = false;

  @override
  void sendFeature(List<int> data, int length) {
    if (failNext) {
      failNext = false;
      throw HidException('falha simulada');
    }
    sent.add(List.of(data));
  }

  @override
  Uint8List getFeature(int reportId, int length) => infoTable();

  @override
  void close() {}
}
