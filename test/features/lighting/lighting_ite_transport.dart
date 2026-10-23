import 'dart:typed_data';

import 'package:lumivent/core/platform/hid_exception.dart' show HidException;
import 'package:lumivent/features/devices/infrastructure/drivers/ite5702/ite_transport.dart';

class LightingIteTransport implements IteTransport {
  final sent = <List<int>>[];
  bool failNext = false;
  @override
  void sendFeature(List<int> data, int length) {
    if (failNext) {
      failNext = false;
      throw HidException('ITE failure');
    }
    sent.add(List.of(data));
  }

  @override
  Uint8List getFeature(int reportId, int length) => Uint8List(64);
  @override
  void close() {}
}
