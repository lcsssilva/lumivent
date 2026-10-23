import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/autostart_state.dart';
import '../domain/autostart_service.dart';

final autostartServiceProvider = Provider<AutostartService>(
  (ref) => throw UnimplementedError('autostartServiceProvider'),
);

class AutostartNotifier extends AsyncNotifier<AutostartState> {
  @override
  Future<AutostartState> build() => ref.read(autostartServiceProvider).status();

  Future<void> setEnabled(bool on) async {
    final svc = ref.read(autostartServiceProvider);
    state = await AsyncValue.guard(() async {
      on ? await svc.enable() : await svc.disable();
      return svc.status();
    });
  }
}

final autostartProvider =
    AsyncNotifierProvider<AutostartNotifier, AutostartState>(
      AutostartNotifier.new,
    );
