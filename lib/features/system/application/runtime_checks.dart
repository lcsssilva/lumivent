import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../fans/fans.dart' show FansStatus, fansStatusProvider;
import '../../lighting/lighting.dart'
    show
        LightDeviceId,
        LightOutputState,
        LightOutputStatus,
        LightingStatus,
        OutputFamily,
        lightingStatusProvider;
import '../domain/diagnostics.dart';

/// Checks of what the running engine did to the hardware (plan §4.2, items
/// 3 and 7): the hub state Windows tools may leave behind, and the real frame
/// rate of each lighting family.
///
/// The data is raw; the presentation formats numbers and translates the text.
List<DiagnosticCheck> runtimeChecks(FansStatus? fans, LightingStatus? light) {
  return [
    // Vendor software can leave the motherboard RPM sync on; the hub cannot
    // report it, so this shows what the fans engine did.
    if (fans == null)
      const DiagnosticCheck(DiagnosticId.hubRpmSync, CheckState.pending)
    else if (fans.syncOff)
      const DiagnosticCheck(DiagnosticId.hubRpmSync, CheckState.ok)
    else
      const DiagnosticCheck(DiagnosticId.hubRpmSync, CheckState.warn),
    // Other RGB software can leave the ARGB sync or the merge on; the lighting
    // init turns both off before anything else.
    if (light == null)
      const DiagnosticCheck(DiagnosticId.hubArgbSync, CheckState.pending)
    else if (light.devices[LightDeviceId.alv2Group1]?.state ==
        LightOutputState.ok)
      const DiagnosticCheck(DiagnosticId.hubArgbSync, CheckState.ok)
    else
      DiagnosticCheck(
        DiagnosticId.hubArgbSync,
        CheckState.warn,
        HubArgbSyncData(light.devices[LightDeviceId.alv2Group1]),
      ),
    if (light != null && light.loops.isNotEmpty)
      DiagnosticCheck(
        DiagnosticId.lightingLoop,
        CheckState.ok,
        LightingLoopData([
          for (final (output, family) in const [
            (OutputFamily.fans, LoopFamily.fans),
            (OutputFamily.ite, LoopFamily.board),
            (OutputFamily.ram, LoopFamily.ram),
            (OutputFamily.gpu, LoopFamily.gpu),
          ])
            LoopSample(
              family,
              fps: light.loops[output]?.fps,
              sendMs: light.loops[output]?.sendMs,
            ),
        ]),
      ),
  ];
}

/// Why the hub ARGB sync check failed: the state of the first AL V2 group
/// ([status] is null when the engine reported nothing for it).
class HubArgbSyncData extends DiagnosticData {
  const HubArgbSyncData(this.status);
  final LightOutputStatus? status;
}

final runtimeChecksProvider = Provider<List<DiagnosticCheck>>(
  (ref) => runtimeChecks(
    ref.watch(fansStatusProvider),
    ref.watch(lightingStatusProvider),
  ),
);
