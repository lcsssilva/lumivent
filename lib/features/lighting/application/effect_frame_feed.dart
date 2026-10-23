import 'package:flutter/foundation.dart';

import '../domain/effect_frame.dart';

/// The preview frame, and whether anything is showing it: without a
/// listener the runner asks the runtime for the LED colors only.
class EffectFrameFeed extends ValueNotifier<EffectFrame?> {
  EffectFrameFeed() : super(null);

  bool get watched => hasListeners;
}
