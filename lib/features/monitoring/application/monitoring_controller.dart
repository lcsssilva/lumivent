import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/engine/engine_host.dart';
import '../domain/metrics.dart';
import '../domain/ssd.dart';
import 'monitoring_messages.dart';

class MonitoringState {
  const MonitoringState({
    this.history = const SensorHistory(),
    this.ssds,
    this.ssdsReadAt,
  });

  final SensorHistory history;

  /// `null` until the first SSD reading.
  final List<SsdInfo>? ssds;
  final DateTime? ssdsReadAt;

  SensorSample? get latest => history.latest;

  MonitoringState copyWith({
    SensorHistory? history,
    List<SsdInfo>? ssds,
    DateTime? ssdsReadAt,
  }) => MonitoringState(
    history: history ?? this.history,
    ssds: ssds ?? this.ssds,
    ssdsReadAt: ssdsReadAt ?? this.ssdsReadAt,
  );
}

/// Live sensors and history received from the engine.
class MonitoringController extends Notifier<MonitoringState> {
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
    NotifierProvider<MonitoringController, MonitoringState>(
      MonitoringController.new,
    );
