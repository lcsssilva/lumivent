import 'dart:typed_data';

import 'package:lumivent/features/devices/infrastructure/drivers/alv2/alv2_transport.dart';

import 'hub_worker_clock.dart';

/// Records packets and the close, in order.
class HubWorkerTransport implements Alv2Transport {
  HubWorkerTransport(this.clock);
  final HubWorkerClock clock;
  final log = <String>[];
  final times = <DateTime>[];
  Uint8List? input;

  void _add(String s) {
    log.add(s);
    times.add(clock.t);
  }

  String _hex(List<int> d) =>
      d.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');

  @override
  void sendFeature(List<int> data, int length) => _add('F ${_hex(data)}');
  @override
  void write(List<int> data, int length) =>
      _add('O ${_hex(data).substring(0, 8)}');
  @override
  Uint8List getInput(int reportId, int length) => input ?? Uint8List(length);
  @override
  void close() => _add('close');
}
