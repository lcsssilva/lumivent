import 'dart:typed_data';

import 'simple_canvas_raster.dart';
import 'simple_raster_state.dart';

/// Result of [SimpleCanvasRaster.tryRaster] / [SimpleCanvasRaster.rasterInto].
class SimpleRaster {
  const SimpleRaster(this.pixels, this.opCount, this.state);

  /// RGBA8888, little endian (`0xAABBGGRR` per pixel).
  final Uint32List pixels;
  final int opCount;
  final SimpleRasterState state;

  Uint8List get rgba =>
      Uint8List.view(pixels.buffer, pixels.offsetInBytes, pixels.lengthInBytes);
}
