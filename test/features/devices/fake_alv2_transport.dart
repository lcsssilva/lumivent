import 'dart:typed_data';

import 'package:lumivent/core/platform/hid_exception.dart';
import 'package:lumivent/features/devices/infrastructure/drivers/alv2/alv2_transport.dart';

import 'fake_clock.dart';
import 'sent.dart';

class FakeAlv2Transport implements Alv2Transport {
  FakeAlv2Transport(this.clock);
  final FakeClock clock;
  final sent = <Sent>[];
  bool failNext = false;

  /// Raw input report returned by `getInput` (zeros when null).
  Uint8List? input;

  void _log(String k, List<int> d, int l) {
    if (failNext) {
      failNext = false;
      throw HidException('falha');
    }
    sent.add(Sent(clock.t, k, List.of(d), l));
  }

  @override
  void sendFeature(List<int> data, int length) => _log('feature', data, length);
  @override
  void write(List<int> data, int length) => _log('output', data, length);
  @override
  Uint8List getInput(int reportId, int length) => input ?? Uint8List(length);
  @override
  void close() {}
}
