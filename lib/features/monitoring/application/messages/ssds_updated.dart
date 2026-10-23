import '../../../../core/engine/engine_event.dart';
import '../../domain/ssd_info.dart';

class SsdsUpdated extends EngineEvent {
  const SsdsUpdated(this.ssds, this.readAt);
  final List<SsdInfo> ssds;
  final DateTime readAt;
}
