// Lighting module domain (pure Dart): LED geometry for each device and the
// rectangle it occupies on the 320×200 canvas.

import 'dart:math' as math;

import 'light_device.dart';
import 'led_point.dart';

const canvasWidth = 320;
const canvasHeight = 200;

/// LEDs per AL120 fan: 8 of the inner ring and 12 of the outer (AL-V2 §3.3).
const ledsPerFan = 20;
const innerRingLeds = 8;
const outerRingLeds = 12;
const chassisLedCount = 47;
const ramLedCount = 12;
const maxFansPerGroup = 6;

/// LEDs of a device in the order the driver consumes them, plus the
/// natural width/height ratio.
class LedLayout {
  const LedLayout(this.leds, this.aspect);
  final List<LedPoint> leds;
  final double aspect;

  int get length => leds.length;
}

/// Ring radii as a fraction of the fan side.
///
/// The exact fan geometry is unavailable:
/// the circles below are an approximation (LED order, which the driver requires,
/// comes from AL-V2 §3.3).
const _innerRadius = 0.18;
const _outerRadius = 0.42;

/// Geometry for [id]. For fans, [fanQuantity] (0–6) is the number of fans in the
/// group, side by side; ignored for other devices.
LedLayout ledLayoutFor(LightDeviceId id, {int fanQuantity = 0}) {
  if (id.isFan) return _fanGroupLayouts[fanQuantity.clamp(0, maxFansPerGroup)];
  return switch (id) {
    LightDeviceId.chassis => _chassis,
    LightDeviceId.motherboard => _motherboard,
    LightDeviceId.ram1 || LightDeviceId.ram2 => _ram,
    _ => const LedLayout([], 1),
  };
}

/// Number of LEDs for [id] (fans: [fanQuantity] × 20).
int ledCountFor(LightDeviceId id, {int fanQuantity = 0}) => switch (id) {
  _ when id.isFan => fanQuantity.clamp(0, maxFansPerGroup) * ledsPerFan,
  LightDeviceId.chassis => chassisLedCount,
  LightDeviceId.motherboard => 3,
  LightDeviceId.ram1 || LightDeviceId.ram2 => ramLedCount,
  _ => 0,
};

/// Fan group layouts by quantity (0–[maxFansPerGroup]), built once: the
/// canvas painter, the effect sampler and the frame loop ask for them every
/// frame.
final _fanGroupLayouts = List<LedLayout>.unmodifiable([
  for (var q = 0; q <= maxFansPerGroup; q++) _fanGroupLayout(q),
]);

/// Fans side by side; each with the inner ring (8) and then the outer (12),
/// starting at the left (the cable side) and proceeding counterclockwise, as
/// seen on the hardware (checklist 2026-10-19).
LedLayout _fanGroupLayout(int q) {
  if (q == 0) return const LedLayout([], 1);
  final leds = <LedPoint>[];
  for (var f = 0; f < q; f++) {
    final cx = (f + 0.5) / q;
    void ring(int n, double radius) {
      for (var k = 0; k < n; k++) {
        final a = math.pi - 2 * math.pi * k / n;
        leds.add(
          LedPoint(cx + radius * math.cos(a) / q, 0.5 + radius * math.sin(a)),
        );
      }
    }

    ring(innerRingLeds, _innerRadius);
    ring(outerRingLeds, _outerRadius);
  }
  return LedLayout(List.unmodifiable(leds), q.toDouble());
}

/// D_LED1: index 0 on the right (ITE §0.1.2).
final _chassis = LedLayout(
  List.unmodifiable([
    for (var i = 0; i < chassisLedCount; i++)
      LedPoint(1 - i / (chassisLedCount - 1), 0.5),
  ]),
  24,
);

/// Zones `0x20` (IO Shield 1), `0x22` (LED_CPU) and `0x23` (IO Shield 2).
const _motherboard = LedLayout([
  LedPoint(0.15, 0.3),
  LedPoint(0.6, 0.15),
  LedPoint(0.15, 0.7),
], 1);

/// Fury DDR5: 12 LEDs in a column. Index 0 at the connector end (bottom of the
/// canvas), verified on hardware 2026-10-19.
final _ram = LedLayout(
  List.unmodifiable([
    for (var i = 0; i < ramLedCount; i++)
      LedPoint(0.5, 1 - (i + 0.5) / ramLedCount),
  ]),
  0.15,
);
