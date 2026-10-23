import '../../domain/rgb.dart';

class SentGpu {
  const SentGpu(this.color, this.brightness, this.at);

  final Rgb color;
  final int brightness;
  final DateTime at;
}
