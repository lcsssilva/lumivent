import 'dart:typed_data';

import '../../../../../core/platform/hid_api.dart';

/// Minimal hub transport (feature / output / input). The real [HidDevice]
/// comes in through an adapter; the tests use a fake.
abstract interface class Alv2Transport {
  void sendFeature(List<int> data, int length);
  void write(List<int> data, int length);
  Uint8List getInput(int reportId, int length);
  void close();
}
