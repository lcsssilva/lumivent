import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/theme.dart';
import '../../../core/ui/widgets.dart';
import '../../preferences/preferences.dart';
import '../application/monitoring_controller.dart';
import '../domain/metrics.dart';
import '../domain/ssd.dart';
import 'format.dart';
import 'metric_widgets.dart';

/// SSD tool: health and SMART data for each NVMe drive.
class SsdSection extends ConsumerWidget {
  const SsdSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ssds = ref.watch(monitoringProvider.select((s) => s.ssds));
    final readAt = ref.watch(monitoringProvider.select((s) => s.ssdsReadAt));
    final latest = ref.watch(monitoringProvider.select((s) => s.latest));
    final unit = ref.watch(
      preferencesProvider.select((p) => p.temperatureUnit),
    );
    final missingSmart =
        ssds?.where((s) => s.smart == null).toList() ?? const [];
    return WeCard(
      title: 'Armazenamento',
      trailing: readAt == null
          ? null
          : Text(
              'atualiza a cada minuto · lido às ${_hms(readAt)}',
              style: const TextStyle(color: WeColors.muted, fontSize: 12),
            ),
      child: switch (ssds) {
        null => const NoReading('Lendo SSDs…'),
        [] => const NoReading('Nenhum SSD NVMe encontrado.'),
        _ => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (missingSmart.isNotEmpty) _SmartBanner(missingSmart),
            for (final (i, ssd) in ssds.indexed) ...[
              if (i > 0) const Divider(height: 1),
              _SsdRow(
                ssd,
                liveTemp: latest?[Metrics.ssdTemp(ssd.controller)],
                unit: unit,
              ),
            ],
          ],
        ),
      },
    );
  }
}

String _hms(DateTime t) =>
    [t.hour, t.minute, t.second].map((v) => '$v'.padLeft(2, '0')).join(':');

class _SmartBanner extends StatelessWidget {
  const _SmartBanner(this.ssds);
  final List<SsdInfo> ssds;

  @override
  Widget build(BuildContext context) {
    final reasons = {for (final s in ssds) ?s.smartError};
    return Container(
      margin: const EdgeInsets.only(bottom: WeSizes.unit * 1.5),
      padding: const EdgeInsets.all(WeSizes.unit * 1.5),
      decoration: BoxDecoration(
        color: WeColors.warn.withValues(alpha: .1),
        border: Border.all(color: WeColors.warn.withValues(alpha: .4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: WeColors.warn, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SMART indisponível: vida restante, TBW e horas ligado não estão disponíveis.',
                ),
                const SizedBox(height: 2),
                Text(
                  reasons.join(' · '),
                  style: const TextStyle(color: WeColors.muted, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SsdRow extends StatelessWidget {
  const _SsdRow(this.ssd, {required this.liveTemp, required this.unit});
  final SsdInfo ssd;
  final double? liveTemp;
  final TemperatureUnit unit;

  @override
  Widget build(BuildContext context) {
    final smart = ssd.smart;
    final health = smart?.health;
    final ident = [
      ssd.controller,
      if (ssd.capacityBytes case final c?) formatStorage(c),
      if (ssd.firmware.isNotEmpty) 'fw ${ssd.firmware}',
      if (ssd.serial.isNotEmpty) 'S/N ${ssd.serial}',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: WeSizes.unit * 1.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.save_outlined, color: WeColors.muted, size: 22),
              const SizedBox(width: WeSizes.unit * 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ssd.model,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ident,
                      style: const TextStyle(
                        color: WeColors.muted,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: WeSizes.unit * 2),
              health == null
                  ? const StatusPill(label: 'Sem SMART', color: WeColors.muted)
                  : StatusPill(
                      label: healthLabel(health),
                      color: healthColor(health),
                    ),
              const SizedBox(width: WeSizes.unit * 1.5),
              OutlinedButton(
                onPressed: smart == null
                    ? null
                    : () => showSmartDetails(context, ssd, unit),
                child: const Text('Detalhes'),
              ),
            ],
          ),
          const SizedBox(height: WeSizes.unit * 1.5),
          Padding(
            padding: const EdgeInsets.only(left: 22 + WeSizes.unit * 2),
            child: Wrap(
              spacing: WeSizes.unit * 4,
              runSpacing: WeSizes.unit * 1.5,
              children: [
                if (smart != null) _LifeTile(smart),
                _tile(
                  'Temperatura',
                  formatTemp(liveTemp ?? smart?.compositeCelsius, unit),
                ),
                if (smart != null) ...[
                  _tile('Horas ligado', '${grouped(smart.powerOnHours)} h'),
                  _tile('Escritos', formatStorage(smart.bytesWritten)),
                  _tile('Lidos', formatStorage(smart.bytesRead)),
                  _tile('Ciclos de energia', grouped(smart.powerCycles)),
                  _tile(
                    'Desligamentos inseguros',
                    grouped(smart.unsafeShutdowns),
                  ),
                  _tile(
                    'Erros de mídia',
                    grouped(smart.mediaErrors),
                    color: smart.mediaErrors > 0 ? WeColors.danger : null,
                  ),
                  _tile(
                    'Reserva disponível',
                    '${smart.availableSpare} %',
                    color: smart.availableSpare <= smart.availableSpareThreshold
                        ? WeColors.danger
                        : null,
                  ),
                  _tile(
                    'Alerta crítico',
                    smart.warnings.isEmpty
                        ? 'Nenhum'
                        : smart.warnings.join(', '),
                    color: smart.warnings.isEmpty ? null : WeColors.danger,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _tile(String label, String value, {Color? color}) =>
      ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(color: WeColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      );
}

class _LifeTile extends StatelessWidget {
  const _LifeTile(this.smart);
  final NvmeSmartLog smart;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 128,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vida restante',
          style: TextStyle(color: WeColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          '${smart.lifeRemaining} %',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: smart.lifeRemaining / 100,
            minHeight: 4,
            backgroundColor: WeColors.surface2,
            color: healthColor(smart.health),
          ),
        ),
      ],
    ),
  );
}

Color healthColor(SsdHealth h) => switch (h) {
  SsdHealth.good => WeColors.ok,
  SsdHealth.caution => WeColors.warn,
  SsdHealth.bad => WeColors.danger,
};

/// Full SMART table for an SSD.
Future<void> showSmartDetails(
  BuildContext context,
  SsdInfo ssd,
  TemperatureUnit unit,
) {
  final s = ssd.smart!;
  String kelvin(int k) => formatTemp(k - 273.15, unit);
  final rows = <(String, String)>[
    (
      'Alerta crítico',
      '0x${s.criticalWarning.toRadixString(16).padLeft(2, '0').toUpperCase()}'
          '${s.warnings.isEmpty ? '' : ' (${s.warnings.join(', ')})'}',
    ),
    ('Temperatura composta', kelvin(s.compositeKelvin)),
    ('Reserva disponível', '${s.availableSpare} %'),
    ('Limite da reserva', '${s.availableSpareThreshold} %'),
    ('Percentual usado', '${s.percentageUsed} %'),
    ('Vida restante', '${s.lifeRemaining} % (${healthLabel(s.health)})'),
    (
      'Data units lidas',
      '${grouped(s.dataUnitsRead)} (${formatStorage(s.bytesRead)})',
    ),
    (
      'Data units escritas',
      '${grouped(s.dataUnitsWritten)} (${formatStorage(s.bytesWritten)})',
    ),
    ('Comandos de leitura', grouped(s.hostReadCommands)),
    ('Comandos de escrita', grouped(s.hostWriteCommands)),
    ('Tempo ocupado do controlador', '${grouped(s.controllerBusyMinutes)} min'),
    ('Ciclos de energia', grouped(s.powerCycles)),
    ('Horas ligado', '${grouped(s.powerOnHours)} h'),
    ('Desligamentos inseguros', grouped(s.unsafeShutdowns)),
    ('Erros de mídia e integridade', grouped(s.mediaErrors)),
    ('Entradas no log de erros', grouped(s.errorLogEntries)),
    (
      'Tempo acima da temperatura de alerta',
      '${grouped(s.warningTempMinutes)} min',
    ),
    (
      'Tempo acima da temperatura crítica',
      '${grouped(s.criticalTempMinutes)} min',
    ),
    for (final (i, k) in s.sensorsKelvin.indexed)
      if (k != 0) ('Sensor de temperatura ${i + 1}', kelvin(k)),
  ];
  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: WeColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WeSizes.radius),
        side: const BorderSide(color: WeColors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(WeSizes.unit * 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ssd.model,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${ssd.controller} · SMART/Health (log 02h)',
                style: const TextStyle(color: WeColors.muted, fontSize: 12.5),
              ),
              const SizedBox(height: WeSizes.unit * 2),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (final (i, (label, value)) in rows.indexed)
                        Container(
                          color: i.isEven
                              ? WeColors.surface2.withValues(alpha: .5)
                              : null,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  label,
                                  style: const TextStyle(color: WeColors.muted),
                                ),
                              ),
                              SelectableText(
                                value,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: WeSizes.unit * 2),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fechar'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
