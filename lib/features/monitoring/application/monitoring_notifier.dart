import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/engine/isolate_engine.dart';
import '../domain/sensor_history.dart';
import 'request_sensor_history.dart';
import 'sensors_updated.dart';
import 'sensor_history_replay.dart';
import 'ssds_updated.dart';
import 'monitoring_state.dart';

/// Live sensors and history received from the engine.
class MonitoringNotifier extends Notifier<MonitoringState> {
  @override
  MonitoringState build() {
    final engine = ref.watch(engineProvider);
    final sub = engine.events.listen((e) {
      switch (e) {
        case SensorsUpdated(:final sample):
          state = state.copyWith(history: state.history.added(sample));
        case SensorHistoryReplay(:final samples):
          state = state.copyWith(
            history: SensorHistory.from(
              samples,
              capacity: state.history.capacity,
            ),
          );
        case SsdsUpdated(:final ssds, :final readAt):
          state = state.copyWith(ssds: ssds, ssdsReadAt: readAt);
      }
    });
    ref.onDispose(sub.cancel);
    engine.send(const RequestSensorHistory());
    final ssds = engine.lastEvent<SsdsUpdated>();
    return MonitoringState(ssds: ssds?.ssds, ssdsReadAt: ssds?.readAt);
  }
}

final monitoringProvider =
    NotifierProvider<MonitoringNotifier, MonitoringState>(
      MonitoringNotifier.new,
    );
