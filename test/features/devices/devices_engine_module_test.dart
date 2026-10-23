import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/core/engine/engine_event.dart';
import 'package:lumivent/features/devices/devices.dart';

import 'fake_detector.dart';

void main() {
  test('scans at startup, on request, and when presence changes', () async {
    final detector = FakeDetector();
    final events = <EngineEvent>[];
    final m = DevicesEngineModule(
      () => detector,
      poll: const Duration(milliseconds: 10),
    )..start(events.add);
    expect(detector.scans, 1);

    await Future<void>.delayed(const Duration(milliseconds: 35));
    expect(
      detector.scans,
      1,
      reason: 'unchanged presence does not trigger another scan',
    );

    detector.key = 'b';
    await Future<void>.delayed(const Duration(milliseconds: 35));
    expect(detector.scans, 2);

    expect(m.handle(const RescanDevices()), isTrue);
    expect(detector.scans, 3);
    expect(events.whereType<DevicesChanged>(), hasLength(3));

    m.stop();
    expect(detector.disposed, isTrue);
  });
}
