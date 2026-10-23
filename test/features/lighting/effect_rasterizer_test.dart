import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/lighting/infrastructure/html_effects/canvas_op.dart';
import 'package:lumivent/features/lighting/infrastructure/html_effects/effect_rasterizer.dart';

/// `fillStyle = color; fillRect(x, y, w, h)` in the shim's binary layout.
Uint8List _fill(String color, List<double> rect) {
  final bytes = BytesBuilder()
    ..addByte(CanvasOp.fillStyle)
    ..addByte(1)
    ..addByte(1)
    ..add(
      (ByteData(
        2,
      )..setUint16(0, color.length, Endian.little)).buffer.asUint8List(),
    )
    ..add(color.codeUnits)
    ..addByte(CanvasOp.fillRect)
    ..addByte(rect.length);
  for (final v in rect) {
    bytes
      ..addByte(0)
      ..add(
        (ByteData(4)..setFloat32(0, v, Endian.little)).buffer.asUint8List(),
      );
  }
  return bytes.takeBytes();
}

void main() {
  testWidgets('a preview that finishes decoding after dispose is dropped', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final rasterizer = EffectRasterizer();
      final rgba = Uint8List(
        EffectRasterizer.width * EffectRasterizer.height * 4,
      );
      rasterizer.acceptSimple(rgba, 1);
      expect(rasterizer.image, isNull, reason: 'the first decode just started');
      rasterizer.dispose();

      // Past the preview throttle, so the next read starts a new decode and
      // returns whatever preview survived the dispose.
      await Future<void>.delayed(const Duration(milliseconds: 500));
      rasterizer.acceptSimple(rgba, 1);
      expect(rasterizer.image, isNull);
      rasterizer.dispose();
    });
  });

  testWidgets('the general replay draws on top of the retained fast canvas', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final rasterizer = EffectRasterizer();
      const w = EffectRasterizer.width, h = EffectRasterizer.height;
      // A fast frame fills the whole canvas red (RGBA bytes).
      final red = Uint8List(w * h * 4);
      for (var i = 0; i < red.length; i += 4) {
        red[i] = 255;
        red[i + 3] = 255;
      }
      rasterizer.acceptSimple(red, 1);

      // The next frame needs the general replay and only paints one corner.
      final frame = await rasterizer.drawSlow(_fill('#00ff00', [0, 0, 10, 10]));
      final far = ((h - 1) * w + (w - 1)) * 4;
      expect(frame.rgba.sublist(far, far + 4), [255, 0, 0, 255]);
      expect(frame.rgba.sublist(0, 4), [0, 255, 0, 255]);
      rasterizer.dispose();
    });
  });
}
