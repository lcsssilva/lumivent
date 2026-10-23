import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/engine/isolate_engine.dart';
import 'lighting_status.dart';

/// Last per-device output status from the engine (`null` until the first one).
class LightingStatusNotifier extends Notifier<LightingStatus?> {
  @override
  LightingStatus? build() {
    final engine = ref.watch(engineProvider);
    final sub = engine.events.listen((e) {
      if (e is LightingStatus) state = e;
    });
    ref.onDispose(sub.cancel);
    return engine.lastEvent<LightingStatus>();
  }
}

final lightingStatusProvider =
    NotifierProvider<LightingStatusNotifier, LightingStatus?>(
      LightingStatusNotifier.new,
    );
