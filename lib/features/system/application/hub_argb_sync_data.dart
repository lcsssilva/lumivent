import '../../lighting/lighting.dart' show LightOutputStatus;
import '../domain/diagnostics/diagnostic_data.dart';

/// Why the hub ARGB sync check failed: the state of the first AL V2 group
/// ([status] is null when the engine reported nothing for it).
class HubArgbSyncData extends DiagnosticData {
  const HubArgbSyncData(this.status);
  final LightOutputStatus? status;
}
