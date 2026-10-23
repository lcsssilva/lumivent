import 'package:flutter/foundation.dart' show listEquals;

import '../../domain/light_device.dart';
import '../../domain/rgb.dart';
import 'sent_colors.dart';
import 'sent_gpu.dart';

/// Tracks the last color sent to each output and the safety resend deadline.
class LightingFrameDeduplicator {
  LightingFrameDeduplicator(this.resendEvery);

  final Duration resendEvery;
  final _sent = <LightDeviceId, SentColors>{};
  SentGpu? _sentGpu;

  bool shouldSendColors(LightDeviceId id, List<Rgb> colors, DateTime at) {
    final last = _sent[id];
    return last == null ||
        !listEquals(last.colors, colors) ||
        at.difference(last.at) >= resendEvery;
  }

  bool shouldSendGpu(Rgb color, int brightness, DateTime at) {
    final last = _sentGpu;
    return last == null ||
        last.color != color ||
        last.brightness != brightness ||
        at.difference(last.at) >= resendEvery;
  }

  void recordColors(LightDeviceId id, List<Rgb> colors, DateTime at) {
    _sent[id] = SentColors(colors, at);
  }

  void recordGpu(Rgb color, int brightness, DateTime at) {
    _sentGpu = SentGpu(color, brightness, at);
  }

  void forget(LightDeviceId id) => _sent.remove(id);

  void forgetGpu() => _sentGpu = null;

  void clear() {
    _sent.clear();
    _sentGpu = null;
  }
}
