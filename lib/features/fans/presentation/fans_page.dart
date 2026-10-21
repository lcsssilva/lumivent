import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/app_strings_scope.dart';
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

String _temp(double? c, TemperatureUnit unit) => c == null
    ? '—'
    : unit == TemperatureUnit.fahrenheit
    ? '${(c * 9 / 5 + 32).round()} °F'
    : '${c.round()} °C';

/// Display name of [g], falling back to the catalog's default group name.
String _groupLabel(AppStrings strings, FanGroupConfig g) =>
    g.name.trim().isEmpty ? strings.common.groupName(g.group) : g.name;

String _presetLabel(AppStrings strings, FanPreset p) => switch (p) {
  FanPreset.quiet => strings.fans.presetQuiet,
  FanPreset.standard => strings.fans.presetStandard,
  FanPreset.high => strings.fans.presetHigh,
  FanPreset.full => strings.fans.presetFull,
  FanPreset.fixed => strings.fans.presetFixed,
  FanPreset.user1 => strings.fans.presetUser1,
  FanPreset.user2 => strings.fans.presetUser2,
  FanPreset.user3 => strings.fans.presetUser3,
  FanPreset.user4 => strings.fans.presetUser4,
  FanPreset.custom => strings.fans.presetCustom,
};

/// Short label used in the chart.
String _sourceLabel(AppStrings strings, FanTempSource s) => switch (s) {
  FanTempSource.cpuTctl => strings.fans.sourceCpuTctl,
  FanTempSource.gpuJunction => strings.fans.sourceGpuJunction,
  FanTempSource.gpuEdge => strings.fans.sourceGpuEdge,
  FanTempSource.boardSystem1 => strings.fans.sourceSystem1,
  FanTempSource.boardSystem2 => strings.fans.sourceSystem2,
  FanTempSource.boardPch => strings.fans.sourcePch,
  FanTempSource.boardCpuSocket => strings.fans.sourceCpuSocket,
  FanTempSource.boardVrm => strings.fans.sourceVrm,
  FanTempSource.boardPciex16 => strings.fans.sourcePciex16,
  FanTempSource.boardPciex4 => strings.fans.sourcePciex4,
};

/// Name in the source list: motherboard sensors are grouped under "Motherboard".
String _sourceMenuLabel(AppStrings strings, FanTempSource s) => s.isBoard
    ? '${strings.fans.motherboardPrefix} · ${_sourceLabel(strings, s)}'
    : _sourceLabel(strings, s);

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

String _responseLabel(AppStrings strings, FanResponse r) => switch (r) {
  FanResponse.fast => strings.fans.responseFast,
  FanResponse.normal => strings.fans.responseNormal,
  FanResponse.smooth => strings.fans.responseSmooth,
};

String _responseHint(AppStrings strings, FanResponse r) => switch (r) {
  FanResponse.fast => strings.fans.responseFastHint,
  FanResponse.normal => strings.fans.responseNormalHint,
  FanResponse.smooth => strings.fans.responseSmoothHint,
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
    final strings = context.strings;
    final f = strings.fans;

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
        : '${_sourceLabel(strings, group.source)} ${_temp(temp, unit)}'
              '${differs ? ' ${f.nowTemperature(_temp(rawNow, unit))}' : ''}';
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
              Expanded(
                child: Text(
                  f.groupsTitle,
                  style: const TextStyle(
                    color: WeColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Tooltip(
                message: f.applyAllTooltip(_groupLabel(strings, group)),
                child: FilledButton.tonalIcon(
                  key: const ValueKey('opt-apply-all'),
                  icon: const Icon(Icons.copy_all, size: 18),
                  label: Text(f.applyAllLabel(_groupLabel(strings, group))),
                  onPressed: () {
                    controller.applyCurveToAll(index);
                    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                      SnackBar(
                        content: Text(
                          f.appliedToAll(_groupLabel(strings, group)),
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
            title: f.speedCurve,
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
                        label: Text(_presetLabel(strings, p)),
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
                      ? f.dragFixedHint
                      : f.dragHint(FanPresets.maxPoints),
                  style: const TextStyle(color: WeColors.muted, fontSize: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: WeSizes.unit * 2),
          WeCard(
            title: f.groupOptions,
            child: Column(
              children: [
                SettingRow(
                  title: f.startStop,
                  subtitle: Text(f.startStopHint),
                  control: Switch(
                    key: const ValueKey('opt-startstop'),
                    value: group.startStop,
                    onChanged: (v) =>
                        controller.updateGroup(group.copyWith(startStop: v)),
                  ),
                ),
                const Divider(),
                SettingRow(
                  title: f.temperatureSource,
                  subtitle: Text(f.temperatureSourceHint),
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
                  title: f.temperatureResponse,
                  subtitle: Text(_responseHint(strings, group.response)),
                  control: SegmentedButton<FanResponse>(
                    key: const ValueKey('opt-response'),
                    showSelectedIcon: false,
                    segments: [
                      for (final r in FanResponse.values)
                        ButtonSegment(
                          value: r,
                          label: Text(_responseLabel(strings, r)),
                        ),
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
    final strings = context.strings;
    final sources = [
      for (final s in FanTempSource.values)
        if (!s.isBoard || s == selected || latest?[_sourceMetric(s)] != null) s,
    ];
    Widget row(FanTempSource s) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_sourceMenuLabel(strings, s)),
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
    final strings = context.strings;
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
                        _groupLabel(strings, config),
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
                  hasFan
                      ? '${strings.grouped((rpm ?? 0).round())} RPM'
                      : strings.fans.noFan,
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
    final strings = context.strings;
    final f = strings.fans;
    final s = widget.status;
    final pills = <Widget>[
      if (s != null && s.temp == null)
        StatusPill(label: f.noTemperature, color: WeColors.warn),
      if (widget.hubOk == false)
        StatusPill(label: f.hubUnavailable, color: WeColors.danger),
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
            decoration: InputDecoration(
              labelText: f.groupName,
              hintText: strings.common.groupName(widget.group.group),
              isDense: true,
              counterText: '',
              border: const OutlineInputBorder(),
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
          f.currentRpm,
          widget.rpm == null
              ? '—'
              : '${strings.grouped(widget.rpm!.round())} RPM',
        ),
        stat(f.duty, s?.duty == null ? '—' : '${s!.duty} %'),
        stat(
          f.target,
          s?.targetRpm == null ? '—' : '${strings.grouped(s!.targetRpm!)} RPM',
        ),
        ...pills,
      ],
    );
  }
}
