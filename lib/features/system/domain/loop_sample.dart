import 'diagnostics.dart';

/// Measured rate of one output loop.
class LoopSample {
  const LoopSample(this.family, {this.fps, this.sendMs});
  final LoopFamily family;
  final double? fps;
  final double? sendMs;
}
