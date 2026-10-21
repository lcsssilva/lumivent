import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/theme.dart';
import '../../../core/ui/widgets.dart';
import '../../monitoring/monitoring.dart';
import '../../preferences/preferences.dart';
import '../application/fans_controller.dart';
import '../application/fans_messages.dart';
import '../domain/fan_curve.dart';
import '../domain/fan_group.dart';
import '../domain/fan_response.dart';
import 'fan_curve_editor.dart';

String _int(num v) {
  final s = v.round().abs().toString();
  final b = StringBuffer(v < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return b.toString();
}

String _temp(double? c, TemperatureUnit unit) => c == null
    ? '—'
    : unit == TemperatureUnit.fahrenheit
    ? '${(c * 9 / 5 + 32).round()} °F'
    : '${c.round()} °C';

String _presetLabel(FanPreset p) => switch (p) {
  FanPreset.quiet => 'Quiet',
  FanPreset.standard => 'Standard',
  FanPreset.high => 'High',
  FanPreset.full => 'Full',
  FanPreset.fixed => 'Fixo',
  FanPreset.user1 => 'Usuário 1',
  FanPreset.user2 => 'Usuário 2',
  FanPreset.user3 => 'Usuário 3',
  FanPreset.user4 => 'Usuário 4',
  FanPreset.custom => 'Personalizado',
};

/// Short label used in the chart.
String _sourceLabel(FanTempSource s) => switch (s) {
  FanTempSource.cpuTctl => 'CPU Tctl',
  FanTempSource.gpuJunction => 'GPU junction',
  FanTempSource.gpuEdge => 'GPU edge',
  FanTempSource.boardSystem1 => 'System 1',
  FanTempSource.boardSystem2 => 'System 2',
  FanTempSource.boardPch => 'PCH',
  FanTempSource.boardCpuSocket => 'CPU socket',
  FanTempSource.boardVrm => 'VRM',
  FanTempSource.boardPciex16 => 'PCIEX16',
  FanTempSource.boardPciex4 => 'PCIEX4',
};

/// Name in the source list: motherboard sensors are grouped under "Motherboard".
String _sourceMenuLabel(FanTempSource s) =>
    s.isBoard ? 'Placa-mãe · ${_sourceLabel(s)}' : _sourceLabel(s);

String _sourceMetric(FanTempSource s) => switch (s) {
  FanTempSource.cpuTctl => Metrics.cpuTctl,
  FanTempSource.gpuJunction => Metrics.gpuJunction,
  FanTempSource.gpuEdge => Metrics.gpuEdge,
  FanTempSource.boardSystem1 => 'board.system1',
  FanTempSource.boardSystem2 => 'board.system2',
  FanTempSource.boardPch => 'board.pch',
  FanTempSource.boardCpuSocket => 'board.cpu',
  FanTempSource.boardVrm => 'board.vrm',
  FanTempSource.boardPciex16 => 'board.pciex16',
  FanTempSource.boardPciex4 => 'board.pciex4',
};

String _responseLabel(FanResponse r) => switch (r) {
  FanResponse.fast => 'Rápida',
  FanResponse.normal => 'Normal',
  FanResponse.smooth => 'Suave',
};

String _responseHint(FanResponse r) => switch (r) {
  FanResponse.fast =>
    'Sem média nem rampa: a fan segue a temperatura a cada segundo.',
  FanResponse.normal =>
    'Média de 4 s; sobe até 15%/s e desce 3%/s para evitar picos do Tctl.',
  FanResponse.smooth =>
    'Média de 10 s; sobe até 5%/s e desce 1%/s para fans silenciosas.',
};

/// AL V2 fan speed: groups, presets, options, and curve editor.
class FansPage extends ConsumerStatefulWidget {
  const FansPage({super.key});

  @override
  ConsumerState<FansPage> createState() => _FansPageState();
}

class _FansPageState extends ConsumerState<FansPage> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(fansProvider);
    final history = ref.watch(monitoringProvider.select((m) => m.history));
    final status = ref.watch(fansStatusProvider);
    final unit = ref.watch(
      preferencesProvider.select((p) => p.temperatureUnit),
    );
    final controller = ref.read(fansProvider.notifier);

    final present = [
      for (var g = 0; g < fanGroupCount; g++)
        history.everPositive(Metrics.alv2Rpm(g)),
    ];
    final auto = present.contains(true) ? present.indexOf(true) : 1;
    final index = _selected ?? auto;
    final group = config[index];
    final gStatus = status?.groups.where((g) => g.group == index).firstOrNull;

    final latest = history.latest;
    final rpm = latest?[Metrics.alv2Rpm(index)];
    final metric = _sourceMetric(group.source);
    final raw = latest?[metric];
    final temp = gStatus?.temp ?? raw;
    final rawNow = gStatus?.rawTemp ?? raw;
    final differs =
        temp != null && rawNow != null && (rawNow - temp).abs() >= .5;
    final tempLabel = temp == null
        ? null
        : '${_sourceLabel(group.source)} ${_temp(temp, unit)}'
              '${differs ? ' (agora ${_temp(rawNow, unit)})' : ''}';
    final recent = history.samples.length > 60
        ? history.samples.sublist(history.samples.length - 60)
        : history.samples;
    final trace = [
      for (final s in recent)
        if (s[metric] != null && s[Metrics.alv2Rpm(index)] != null)
          (temp: s[metric]!, rpm: s[Metrics.alv2Rpm(index)]!),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(WeSizes.unit * 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Grupos do hub AL V2',
                  style: TextStyle(
                    color: WeColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Tooltip(
                message:
                    'Copia o preset, os pontos, o Start/Stop, a fonte e a resposta de "${group.name}" para os outros grupos.',
                child: FilledButton.tonalIcon(
                  key: const ValueKey('opt-apply-all'),
                  icon: const Icon(Icons.copy_all, size: 18),
                  label: Text('Aplicar curva "${group.name}" a todos'),
                  onPressed: () {
                    controller.applyCurveToAll(index);
                    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Curva "${group.name}" aplicada a todos os grupos.',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: WeSizes.unit * 1.5),
          Row(
            children: [
              for (var g = 0; g < fanGroupCount; g++) ...[
                if (g > 0) const SizedBox(width: WeSizes.unit * 2),
                Expanded(
                  child: _GroupTile(
                    config: config[g],
                    rpm: latest?[Metrics.alv2Rpm(g)],
                    hasFan: present[g],
                    selected: g == index,
                    onTap: () => setState(() => _selected = g),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: WeSizes.unit * 2),
          WeCard(
            child: _Header(
              key: ValueKey('header-$index'),
              group: group,
              rpm: rpm,
              status: gStatus,
              hubOk: status?.hubOk,
              onName: (n) => controller.updateGroup(
                group.copyWith(name: n.trim().isEmpty ? group.name : n.trim()),
              ),
              onSize: (s) => controller.updateGroup(group.copyWith(size: s)),
            ),
          ),
          const SizedBox(height: WeSizes.unit * 2),
          WeCard(
            title: 'Curva de velocidade',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final p in [
                      FanPreset.quiet,
                      FanPreset.standard,
                      FanPreset.high,
                      FanPreset.full,
                      FanPreset.fixed,
                      FanPreset.user1,
                      FanPreset.user2,
                      FanPreset.user3,
                      FanPreset.user4,
                      FanPreset.custom,
                    ])
                      ChoiceChip(
                        key: ValueKey('preset-${p.name}'),
                        label: Text(_presetLabel(p)),
                        selected: group.preset == p,
                        showCheckmark: false,
                        onSelected: (_) =>
                            controller.updateGroup(group.copyWith(preset: p)),
                      ),
                  ],
                ),
                const SizedBox(height: WeSizes.unit * 2),
                FanCurveEditor(
                  key: const ValueKey('fan-curve-editor'),
                  group: group,
                  live: FanCurveLive(
                    temp: temp,
                    rpm: rpm,
                    duty: gStatus?.duty,
                    tempLabel: tempLabel,
                    trace: trace,
                  ),
                  onChanged: (g) => controller.updateGroup(g, persist: false),
                  onCommit: controller.persist,
                ),
                const SizedBox(height: WeSizes.unit),
                Text(
                  group.preset == FanPreset.fixed
                      ? 'Arraste o ponto para cima ou para baixo para mudar a velocidade fixa.'
                      : 'Arraste os pontos · clique duplo adiciona (máx. ${FanPresets.maxPoints}) · botão direito remove.',
                  style: const TextStyle(color: WeColors.muted, fontSize: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: WeSizes.unit * 2),
          WeCard(
            title: 'Opções do grupo',
            child: Column(
              children: [
                SettingRow(
                  title: 'Start/Stop',
                  subtitle: const Text(
                    'Para as fans abaixo da temperatura do primeiro ponto.',
                  ),
                  control: Switch(
                    key: const ValueKey('opt-startstop'),
                    value: group.startStop,
                    onChanged: (v) =>
                        controller.updateGroup(group.copyWith(startStop: v)),
                  ),
                ),
                const Divider(),
                SettingRow(
                  title: 'Fonte de temperatura',
                  subtitle: const Text(
                    'CPU/GPU para radiadores; temperatura da placa-mãe (System, VRM…) para fans do gabinete.',
                  ),
                  control: _SourcePicker(
                    key: const ValueKey('opt-source'),
                    selected: group.source,
                    latest: latest,
                    unit: unit,
                    onChanged: (s) =>
                        controller.updateGroup(group.copyWith(source: s)),
                  ),
                ),
                const Divider(),
                SettingRow(
                  title: 'Resposta à temperatura',
                  subtitle: Text(_responseHint(group.response)),
                  control: SegmentedButton<FanResponse>(
                    key: const ValueKey('opt-response'),
                    showSelectedIcon: false,
                    segments: [
                      for (final r in FanResponse.values)
                        ButtonSegment(value: r, label: Text(_responseLabel(r))),
                    ],
                    selected: {group.response},
                    onSelectionChanged: (r) => controller.updateGroup(
                      group.copyWith(response: r.first),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lists sources with the current value beside each name. CPU/GPU come first,
/// followed by the motherboard; unavailable board sources are hidden unless selected.
class _SourcePicker extends StatelessWidget {
  const _SourcePicker({
    super.key,
    required this.selected,
    required this.latest,
    required this.unit,
    required this.onChanged,
  });

  final FanTempSource selected;
  final SensorSample? latest;
  final TemperatureUnit unit;
  final ValueChanged<FanTempSource> onChanged;

  @override
  Widget build(BuildContext context) {
    final sources = [
      for (final s in FanTempSource.values)
        if (!s.isBoard || s == selected || latest?[_sourceMetric(s)] != null) s,
    ];
    Widget row(FanTempSource s) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_sourceMenuLabel(s)),
        const SizedBox(width: WeSizes.unit * 1.5),
        Text(
          _temp(latest?[_sourceMetric(s)], unit),
          style: const TextStyle(color: WeColors.muted, fontSize: 12.5),
        ),
      ],
    );
    return DropdownButton<FanTempSource>(
      value: selected,
      underline: const SizedBox.shrink(),
      borderRadius: BorderRadius.circular(WeSizes.radius),
      items: [
        for (final s in sources) DropdownMenuItem(value: s, child: row(s)),
      ],
      onChanged: (s) {
        if (s != null) onChanged(s);
      },
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({
    required this.config,
    required this.rpm,
    required this.hasFan,
    required this.selected,
    required this.onTap,
  });

  final FanGroupConfig config;
  final double? rpm;
  final bool hasFan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(WeSizes.radius);
    return Opacity(
      opacity: hasFan || selected ? 1 : .5,
      child: Material(
        color: selected
            ? WeColors.accent.withValues(alpha: .12)
            : WeColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: shape,
          side: BorderSide(color: selected ? WeColors.accent : WeColors.border),
        ),
        child: InkWell(
          key: ValueKey('group-${config.group}'),
          borderRadius: shape,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(WeSizes.unit * 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        config.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      '${config.size.maxRpm == 2000 ? 120 : 140} mm',
                      style: const TextStyle(
                        color: WeColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  hasFan ? '${_int(rpm ?? 0)} RPM' : 'sem fan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: hasFan ? WeColors.text : WeColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatefulWidget {
  const _Header({
    super.key,
    required this.group,
    required this.rpm,
    required this.status,
    required this.hubOk,
    required this.onName,
    required this.onSize,
  });

  final FanGroupConfig group;
  final double? rpm;
  final FanGroupStatus? status;
  final bool? hubOk;
  final ValueChanged<String> onName;
  final ValueChanged<FanSize> onSize;

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> {
  late final _controller = TextEditingController(text: widget.group.name);
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _commit();
    });
  }

  @override
  void didUpdateWidget(_Header old) {
    super.didUpdateWidget(old);
    if (!_focus.hasFocus && _controller.text != widget.group.name) {
      _controller.text = widget.group.name;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _commit() {
    final t = _controller.text.trim();
    if (t.isEmpty) {
      _controller.text = widget.group.name;
    } else if (t != widget.group.name) {
      widget.onName(t);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.status;
    final pills = <Widget>[
      if (s != null && s.temp == null)
        const StatusPill(label: 'Sem temperatura', color: WeColors.warn),
      if (widget.hubOk == false)
        const StatusPill(label: 'Hub indisponível', color: WeColors.danger),
    ];
    Widget stat(String label, String value) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: WeColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ],
    );
    return Wrap(
      spacing: WeSizes.unit * 3,
      runSpacing: WeSizes.unit * 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 220,
          child: TextField(
            key: const ValueKey('group-name'),
            controller: _controller,
            focusNode: _focus,
            maxLength: 24,
            decoration: const InputDecoration(
              labelText: 'Nome do grupo',
              isDense: true,
              counterText: '',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _commit(),
          ),
        ),
        SegmentedButton<FanSize>(
          key: const ValueKey('group-size'),
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: FanSize.mm120, label: Text('120 mm')),
            ButtonSegment(value: FanSize.mm140, label: Text('140 mm')),
          ],
          selected: {widget.group.size},
          onSelectionChanged: (v) => widget.onSize(v.first),
        ),
        stat(
          'RPM atual',
          widget.rpm == null ? '—' : '${_int(widget.rpm!)} RPM',
        ),
        stat('Duty', s?.duty == null ? '—' : '${s!.duty} %'),
        stat('Alvo', s?.targetRpm == null ? '—' : '${_int(s!.targetRpm!)} RPM'),
        ...pills,
      ],
    );
  }
}
