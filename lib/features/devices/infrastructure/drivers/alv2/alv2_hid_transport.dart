import 'dart:typed_data';

import '../../../../../core/platform/hid_api.dart';
import 'alv2_transport.dart';

class Alv2HidTransport implements Alv2Transport {
  Alv2HidTransport(this._dev);
  final HidDevice _dev;

  @override
  void sendFeature(List<int> data, int length) =>
      _dev.sendFeature(data, length);
  @override
  void write(List<int> data, int length) => _dev.write(data, length);
  @override
  Uint8List getInput(int reportId, int length) =>
      _dev.getInput(reportId, length);
  @override
  void close() => _dev.close();
}
