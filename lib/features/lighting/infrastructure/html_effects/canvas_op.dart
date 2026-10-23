/// Opcodes shared with the JS shim. Keep the two tables in sync.
abstract final class CanvasOp {
  static const unknown = 0;
  static const fillStyle = 1, strokeStyle = 2, lineWidth = 3, alpha = 4;
  static const composite = 5, lineCap = 6, lineJoin = 7;
  static const save = 8, restore = 9;
  static const translate = 10, rotate = 11, scale = 12, transform = 13;
  static const setTransform = 14;
  static const clearRect = 15, fillRect = 16, strokeRect = 17;
  static const beginPath = 18, closePath = 19, moveTo = 20, lineTo = 21;
  static const rect = 22, arc = 23, ellipse = 24, quadratic = 25, bezier = 26;
  static const fill = 27, stroke = 28, clip = 29;
  static const linearGradient = 30, radialGradient = 31, colorStop = 32;

  /// Compact opaque fill rect: opcode, 4×int16, packed ARGB (13 bytes).
  static const fillRect16 = 33;

  /// Fill style as HSL (h, s, l floats) when `hsl()` is parsed in Dart.
  static const hslStyle = 34;

  /// Compact opaque HSL fill rect: opcode, 4×int16, int16 hue×10, u8 s, u8 l.
  static const fillRect16Hsl = 35;
}
