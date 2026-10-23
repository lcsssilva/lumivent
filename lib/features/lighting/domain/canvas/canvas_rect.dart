import '../light_device.dart';
import 'led_layout.dart';
import 'led_point.dart';

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
