import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/lighting/domain/hardware_mode/hardware_timing.dart';

void main() {
  test('effect speed maps to the five firmware levels', () {
    expect(alv2SpeedLevel(1), 0);
    expect(alv2SpeedLevel(100), 4);
    expect(alv2SpeedLevel(50), 2);
    // Default speed of the breathing effect.
    expect(alv2SpeedLevel(30), 1);
  });

  test('breathing period comes from the table', () {
    for (var level = 0; level <= 4; level++) {
      final speed = 1 + level * 99 / 4;
      expect(
        alv2BreathingPeriod(speed).inMilliseconds,
        alv2BreathingPeriodsMs[level],
      );
    }
  });

  test('measured breathing periods get shorter with the level', () {
    expect(alv2BreathingPeriodsMs, [11225, 9109, 7031, 4973, 2875]);
  });

  test('breathing canvas is dark at the firmware first trough', () {
    const speed = 50;
    final period = alv2BreathingPeriod(speed);
    final seconds = period.inMicroseconds / 1e6;
    final trough =
        breathingFirstTroughPhase * seconds +
        breathingFirstTroughDelay.inMicroseconds / 1e6;
    const anchor = 10.0;
    // The native effect is dark at 0: that is the firmware's first trough.
    expect(
      breathingEffectTime(
        showAt: anchor + trough,
        anchor: anchor,
        period: period,
      ),
      closeTo(0, 1e-9),
    );
    // Right after the send the firmware is bright, just past its peak: so
    // is the canvas (the peak is half a period before the trough).
    final atSend = breathingEffectTime(
      showAt: anchor,
      anchor: anchor,
      period: period,
    );
    expect(atSend / seconds, closeTo(-0.5 + 0.09, 0.03));
  });
}
