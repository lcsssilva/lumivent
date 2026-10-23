import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/lighting/application/frames/lighting_frame_deduplicator.dart';
import 'package:lumivent/features/lighting/domain/light_device.dart';
import 'package:lumivent/features/lighting/domain/rgb.dart';

void main() {
  group('LightingFrameDeduplicator', () {
    final start = DateTime(2026);
    const frame = [Rgb(1, 2, 3), Rgb(4, 5, 6)];

    test(
      'resends changed colors and unchanged colors at the safety interval',
      () {
        final deduplicator = LightingFrameDeduplicator(
          const Duration(seconds: 5),
        );
        const id = LightDeviceId.alv2Group1;

        expect(deduplicator.shouldSendColors(id, frame, start), isTrue);
        deduplicator.recordColors(id, frame, start);
        expect(
          deduplicator.shouldSendColors(
            id,
            frame,
            start.add(const Duration(seconds: 4)),
          ),
          isFalse,
        );
        expect(
          deduplicator.shouldSendColors(
            id,
            frame,
            start.add(const Duration(seconds: 5)),
          ),
          isTrue,
        );
        expect(
          deduplicator.shouldSendColors(id, const [
            Rgb(1, 2, 3),
            Rgb(4, 5, 7),
          ], start.add(const Duration(seconds: 1))),
          isTrue,
        );
      },
    );

    test('deduplicates GPU color and brightness independently', () {
      final deduplicator = LightingFrameDeduplicator(
        const Duration(seconds: 5),
      );
      const color = Rgb(1, 2, 3);

      expect(deduplicator.shouldSendGpu(color, 4, start), isTrue);
      deduplicator.recordGpu(color, 4, start);
      expect(
        deduplicator.shouldSendGpu(
          color,
          4,
          start.add(const Duration(seconds: 4)),
        ),
        isFalse,
      );
      expect(
        deduplicator.shouldSendGpu(
          color,
          5,
          start.add(const Duration(seconds: 1)),
        ),
        isTrue,
      );
    });
  });
}
