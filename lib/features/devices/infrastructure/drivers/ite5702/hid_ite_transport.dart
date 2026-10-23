import 'dart:typed_data';

import '../../../../../core/platform/hid_api.dart';
import 'ite_transport.dart';

class HidIteTransport implements IteTransport {
  HidIteTransport(this._dev);
  final HidDevice _dev;

  @override
  void sendFeature(List<int> data, int length) =>
      _dev.sendFeature(data, length);

  @override
  Uint8List getFeature(int reportId, int length) =>
      _dev.getFeature(reportId, length);

  @override
  void close() => _dev.close();
}
