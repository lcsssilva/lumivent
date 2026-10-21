import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../fans/fans.dart' show FansStatus, fansStatusProvider;
import '../../lighting/lighting.dart'
    show
        LightDeviceId,
        LightOutputState,
        LightingStatus,
        LoopStats,
        OutputFamily,
        lightingStatusProvider;
import '../domain/diagnostics.dart';

/// Checks of what the running engine did to the hardware (plan §4.2, items
/// 3 and 7): the hub state Windows tools may leave behind, and the real frame
/// rate of each lighting family.
List<DiagnosticCheck> runtimeChecks(FansStatus? fans, LightingStatus? light) {
  return [
    // Vendor software can leave the motherboard RPM sync on; the hub cannot
    // report it, so this shows what the fans engine did.
    if (fans == null)
      const DiagnosticCheck(
        'Sync de RPM do hub',
        CheckState.pending,
        'Esperando o primeiro ciclo das fans.',
      )
    else if (fans.syncOff)
      const DiagnosticCheck(
        'Sync de RPM do hub',
        CheckState.ok,
        'Desligado pelo app nesta sessão (o software do fabricante pode tê-lo '
            'deixado ligado no Windows).',
      )
    else
      const DiagnosticCheck(
        'Sync de RPM do hub',
        CheckState.warn,
        'O hub ainda não aceitou o desligamento; as fans podem seguir a '
            'placa-mãe. O app tenta de novo a cada ciclo.',
      ),
    // Other RGB software can leave the ARGB sync or the merge on; the lighting
    // init turns both off before anything else.
    if (light == null)
      const DiagnosticCheck(
        'Sync ARGB e merge do hub',
        CheckState.pending,
        'Esperando a iluminação.',
      )
    else if (light.devices[LightDeviceId.alv2Group1]?.state ==
        LightOutputState.ok)
      const DiagnosticCheck(
        'Sync ARGB e merge do hub',
        CheckState.ok,
        'Desligados na partida da iluminação (outros programas de RGB podem '
            'tê-los deixado ligados).',
      )
    else
      DiagnosticCheck(
        'Sync ARGB e merge do hub',
        CheckState.warn,
        light.devices[LightDeviceId.alv2Group1]?.detail ??
            'Hub AL V2 indisponível.',
      ),
    if (light != null && light.loops.isNotEmpty)
      DiagnosticCheck(
        'Laço da iluminação',
        CheckState.ok,
        [
          for (final (f, name) in const [
            (OutputFamily.fans, 'fans'),
            (OutputFamily.ite, 'placa/gabinete'),
            (OutputFamily.ram, 'RAM'),
            (OutputFamily.gpu, 'GPU'),
          ])
            '$name ${_loop(light.loops[f])}',
        ].join(' · '),
      ),
  ];
}

String _loop(LoopStats? s) {
  if (s == null) return '—';
  String n(double v) => v.toStringAsFixed(1).replaceAll('.', ',');
  final send = s.sendMs;
  return send == null ? '${n(s.fps)} fps' : '${n(s.fps)} fps, ${n(send)} ms';
}

final runtimeChecksProvider = Provider<List<DiagnosticCheck>>(
  (ref) => runtimeChecks(
    ref.watch(fansStatusProvider),
    ref.watch(lightingStatusProvider),
  ),
);
