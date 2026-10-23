import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/engine/isolate_engine.dart';
import 'messages/fans_status.dart';

/// Last fan loop cycle in the engine (`null` until the first cycle).
class FansStatusNotifier extends Notifier<FansStatus?> {
  @override
  FansStatus? build() {
    final engine = ref.watch(engineProvider);
    final sub = engine.events.listen((e) {
      if (e is FansStatus) state = e;
    });
    ref.onDispose(sub.cancel);
    return engine.lastEvent<FansStatus>();
  }
}

final fansStatusProvider = NotifierProvider<FansStatusNotifier, FansStatus?>(
  FansStatusNotifier.new,
);
