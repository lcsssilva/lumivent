import 'dart:typed_data';

import 'package:lumivent/features/devices/infrastructure/drivers/alv2/alv2_transport.dart';

class IoWorkerNoHub implements Alv2Transport {
  @override
  void sendFeature(List<int> data, int length) {}
  @override
  void write(List<int> data, int length) {}
  @override
  Uint8List getInput(int reportId, int length) => Uint8List(length);
  @override
  void close() {}
}
