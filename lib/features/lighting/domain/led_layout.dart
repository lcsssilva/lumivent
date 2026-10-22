// Lighting module domain (pure Dart): LED geometry for each device and the
// rectangle it occupies on the 320×200 canvas.

import 'dart:math' as math;

import 'light_device.dart';

const canvasWidth = 320;
const canvasHeight = 200;

/// LEDs per AL120 fan: 8 of the inner ring and 12 of the outer (AL-V2 §3.3).
const ledsPerFan = 20;
const innerRingLeds = 8;
const outerRingLeds = 12;
const chassisLedCount = 47;
const ramLedCount = 12;
const maxFansPerGroup = 6;

/// Point in local device coordinates, normalized to [0,1]².
class LedPoint {
  const LedPoint(this.x, this.y);
  final double x, y;

  @override
  String toString() => 'LedPoint($x, $y)';
}

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
  if (id.isFan) return _fanGroupLayout(fanQuantity.clamp(0, maxFansPerGroup));
  return switch (id) {
    LightDeviceId.chassis => _chassis,
    LightDeviceId.motherboard => _motherboard,
    LightDeviceId.ram1 || LightDeviceId.ram2 => _ram,
    _ => const LedLayout([], 1),
  };
}

/// Per-owner cache for the dynamically generated fan group layouts.
///
/// Keeping this cache on the lighting engine avoids mutable domain-level
/// globals while preserving the frame loop's allocation behavior.
class LedLayoutCache {
  final _fanLayouts = <int, LedLayout>{};

  LedLayout forDevice(LightDeviceId id, {int fanQuantity = 0}) {
    if (!id.isFan) return ledLayoutFor(id, fanQuantity: fanQuantity);
    final quantity = fanQuantity.clamp(0, maxFansPerGroup);
    return _fanLayouts.putIfAbsent(quantity, () => _fanGroupLayout(quantity));
  }
}

/// Number of LEDs for [id] (fans: [fanQuantity] × 20).
int ledCountFor(LightDeviceId id, {int fanQuantity = 0}) => switch (id) {
  _ when id.isFan => fanQuantity.clamp(0, maxFansPerGroup) * ledsPerFan,
  LightDeviceId.chassis => chassisLedCount,
  LightDeviceId.motherboard => 3,
  LightDeviceId.ram1 || LightDeviceId.ram2 => ramLedCount,
  _ => 0,
};

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

/// Rectangle occupied by a device, in canvas units.
class CanvasRect {
  const CanvasRect(this.x, this.y, this.w, this.h);

  final double x, y, w, h;

  double get right => x + w;
  double get bottom => y + h;

  /// Local point (0–1) -> canvas point, always within 0..320 × 0..200.
  (double, double) map(LedPoint p) => (
    (x + p.x * w).clamp(0.0, canvasWidth.toDouble()),
    (y + p.y * h).clamp(0.0, canvasHeight.toDouble()),
  );

  /// Version with a minimum size of 1 and integer coordinates inside the canvas.
  CanvasRect clamped() {
    final nw = w.isNaN ? 1.0 : w.clamp(1.0, canvasWidth.toDouble());
    final nh = h.isNaN ? 1.0 : h.clamp(1.0, canvasHeight.toDouble());
    final nx = x.isNaN ? 0.0 : x.clamp(0.0, canvasWidth - nw);
    final ny = y.isNaN ? 0.0 : y.clamp(0.0, canvasHeight - nh);
    return CanvasRect(nx, ny, nw, nh);
  }

  bool overlaps(CanvasRect o) =>
      x < o.right && o.x < right && y < o.bottom && o.y < bottom;

  CanvasRect copyWith({double? x, double? y, double? w, double? h}) =>
      CanvasRect(x ?? this.x, y ?? this.y, w ?? this.w, h ?? this.h);

  /// Default position for [id]: fans in a row at the top, motherboard and memory
  /// in the middle, and the case as a wide strip at the bottom. They do not overlap.
  static CanvasRect defaultFor(LightDeviceId id) => switch (id) {
    LightDeviceId.alv2Group1 => const CanvasRect(5, 0, 100, 100 / 3),
    LightDeviceId.alv2Group2 => const CanvasRect(110, 0, 100, 100 / 3),
    LightDeviceId.alv2Group3 => const CanvasRect(215, 0, 100, 100 / 3),
    LightDeviceId.motherboard => const CanvasRect(10, 45, 100, 100),
    LightDeviceId.ram1 => const CanvasRect(130, 45, 20, 100),
    LightDeviceId.ram2 => const CanvasRect(170, 45, 20, 100),
    LightDeviceId.gpu => const CanvasRect(220, 45, 90, 40),
    LightDeviceId.chassis => const CanvasRect(10, 165, 300, 25),
  };

  Map<String, Object?> toJson() => {'x': x, 'y': y, 'w': w, 'h': h};

  /// Tolerant: missing or invalid fields fall back to [fallback].
  factory CanvasRect.fromJson(Object? json, CanvasRect fallback) {
    if (json is! Map) return fallback;
    double pick(String k, double d) {
      final v = json[k];
      return v is num && v.isFinite ? v.toDouble() : d;
    }

    return CanvasRect(
      pick('x', fallback.x),
      pick('y', fallback.y),
      pick('w', fallback.w),
      pick('h', fallback.h),
    ).clamped();
  }

  @override
  bool operator ==(Object other) =>
      other is CanvasRect &&
      other.x == x &&
      other.y == y &&
      other.w == w &&
      other.h == h;

  @override
  int get hashCode => Object.hash(x, y, w, h);

  @override
  String toString() => 'CanvasRect($x, $y, $w, $h)';
}
