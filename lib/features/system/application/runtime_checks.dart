import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../fans/fans.dart' show FansStatus, fansStatusProvider;
import '../../lighting/lighting.dart'
    show
        LightDeviceId,
        LightOutputState,
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
      DiagnosticCheck(DiagnosticId.hubArgbSync, CheckState.warn, {
        'issue': light.devices[LightDeviceId.alv2Group1]?.issue?.index,
        'args':
            light.devices[LightDeviceId.alv2Group1]?.args ?? const <String>[],
      }),
    if (light != null && light.loops.isNotEmpty)
      DiagnosticCheck(DiagnosticId.lightingLoop, CheckState.ok, {
        'loops': [
          for (final (family, key) in const [
            (OutputFamily.fans, 'fans'),
            (OutputFamily.ite, 'board'),
            (OutputFamily.ram, 'ram'),
            (OutputFamily.gpu, 'gpu'),
          ])
            (key, light.loops[family]?.fps, light.loops[family]?.sendMs),
        ],
      }),
  ];
}

/// Raw loop statistics for one output family.
typedef LoopData = (String family, double? fps, double? sendMs);

final runtimeChecksProvider = Provider<List<DiagnosticCheck>>(
  (ref) => runtimeChecks(
    ref.watch(fansStatusProvider),
    ref.watch(lightingStatusProvider),
  ),
);
