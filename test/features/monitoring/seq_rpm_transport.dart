part of 'monitoring_engine_test.dart';

/// Hub transport whose RPM replies follow [readings] (one per read), for the
/// alternating readings seen while the lighting streams (2026-10-19).
class _SeqRpmTransport extends _RpmTransport {
  _SeqRpmTransport(this.readings);
  final List<List<int>> readings;
  int _i = 0;

  @override
  Uint8List getInput(int reportId, int length) {
    final r = readings[_i++ % readings.length];
    return Uint8List(length)..setRange(0, 10, [
      0xE0,
      0xF0,
      for (final v in r) ...[v >> 8, v & 0xFF],
    ]);
  }
}
