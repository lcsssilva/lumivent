import 'dart:typed_data';

/// One rendered canvas frame: `width × height` pixels in RGBA order.
class EffectFrame {
  const EffectFrame(this.width, this.height, this.rgba);

  final int width, height;
  final Uint8List rgba;

  /// Pixel [x], [y] (clamped to the frame), as 0–255 channels.
  (int, int, int) pixelAt(int x, int y) {
    final ix = x.clamp(0, width - 1);
    final iy = y.clamp(0, height - 1);
    final o = (iy * width + ix) * 4;
    return (rgba[o], rgba[o + 1], rgba[o + 2]);
  }
}
