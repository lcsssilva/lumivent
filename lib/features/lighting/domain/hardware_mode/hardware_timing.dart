// Lighting module domain (pure Dart): timing of the animations that run in
// the firmware of the fans (AL V2 hub).
//
// The canvas runs on the app clock, the hardware modes on their own. To keep
// both in the same phase the engine needs the period and the start instant of
// the firmware animation. The numbers come from a phone video of the
// hardware (docs/plans/checklist-hardware-fase4-1.md §1).

/// Period of the AL V2 firmware `Breathing` at each speed level (0–4), in ms.
///
/// `[OBS]` Measured 2026-10-20 on two phone videos (`breathcal`, brightness
/// per frame with ffmpeg, 5–14 cycles per level, residuals under 0,05 s): the
/// RAM in the same videos ran its programmed periods within 0,1 %, so the
/// video clock is good. The earlier taps (`period_tap.dart`) were ~0,4 s too
/// long on every level: the user's own rhythm, not the fans'.
const alv2BreathingPeriodsMs = <int>[11225, 9109, 7031, 4973, 2875];

/// Firmware speed level (0–4) for an effect speed (1–100), the same mapping
/// the hardware equivalents use.
int alv2SpeedLevel(num speed) {
  final fraction = ((speed - 1) / 99).clamp(0.0, 1.0);
  return (fraction * 4).round();
}

/// Period of the firmware `Breathing` for an effect speed (1–100).
Duration alv2BreathingPeriod(num speed) => Duration(
  milliseconds: alv2BreathingPeriodsMs[alv2SpeedLevel(speed).clamp(0, 4)],
);

/// Where the firmware `Breathing` starts: its first dark point comes this
/// fraction of the period plus [breathingFirstTroughDelay] after the end of
/// the send (when the engine anchors the phase).
///
/// `[OBS]` Same videos: the fans light up **bright** right at the send, just
/// past their peak. `0,41 × T + 0,08 s` gives the first trough of all five
/// levels within 13 ms.
const breathingFirstTroughPhase = 0.41;

/// Fixed part of the first trough time (see [breathingFirstTroughPhase]).
const breathingFirstTroughDelay = Duration(milliseconds: 80);

/// Instant (in effect seconds) the canvas must show for a firmware `Breathing`
/// of [period] that started at [anchor] (effect seconds).
///
/// The native effect is dark at `t = 0` (a raised cosine), so the firmware's
/// first trough is subtracted. The result can be negative right after the
/// send and keeps growing (the cosine handles both), so callers do not need
/// to wrap it.
double breathingEffectTime({
  required double showAt,
  required double anchor,
  required Duration period,
}) =>
    showAt -
    anchor -
    breathingFirstTroughPhase * period.inMicroseconds / 1e6 -
    breathingFirstTroughDelay.inMicroseconds / 1e6;

/// Canvas speed used by effects whose firmware mode has no speed control
/// (`scanner` → Scan): the fans always run at the firmware's fixed pace, so
/// the rest of the canvas uses this speed as well.
///
/// `[OBS]` Measured 2026-10-20 on phone videos of the app: one Scan cycle
/// (there and back) takes 3,040 s on the 3-fan groups (top and bottom; peak
/// times fitted over 133 s) and 1,46 s on the single rear fan. The canvas
/// scanner's period is `100 / speed` s, so 3,040 s → 32,9 (33,1 gave 3,022 s
/// and drifted ~0,7 s ahead in 2 min); the rear fan cannot match both.
const firmwareFixedEffectSpeed = 32.9;
