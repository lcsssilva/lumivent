import 'dart:typed_data';

import 'package:lumivent/core/platform/hid_exception.dart' show HidException;
import 'package:lumivent/features/devices/infrastructure/drivers/alv2/alv2_transport.dart';

class LightingHubTransport implements Alv2Transport {
  final writes = <List<int>>[];

  /// Report length passed to `write` / `sendFeature`, parallel to [writes].
  final lengths = <int>[];
  bool failNext = false;
  void _log(List<int> data, int length) {
    if (failNext) {
      failNext = false;
      throw HidException('hub failure');
    }
    writes.add(List.of(data));
    lengths.add(length);
  }

  @override
  void sendFeature(List<int> data, int length) => _log(data, length);
  @override
  void write(List<int> data, int length) => _log(data, length);
  @override
  Uint8List getInput(int reportId, int length) => Uint8List(length);
  @override
  void close() {}
}
