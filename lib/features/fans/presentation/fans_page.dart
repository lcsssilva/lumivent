import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/app_strings_scope.dart';
import '../../../core/ui/theme.dart';
import '../../../core/ui/status_pill.dart';
import '../../../core/ui/we_card.dart';
import '../../../core/ui/setting_row.dart';
import '../../monitoring/monitoring.dart';
import '../../preferences/preferences.dart';
import '../application/fan_temp_metric.dart';
import '../application/fans_controller.dart';
import '../application/fans_messages.dart';
import '../domain/fan_curve.dart';
import '../domain/fan_group.dart';
import '../domain/fan_response.dart';
import 'fan_curve_editor.dart';

/// Last 60 readings that have both the temperature and RPM metrics.
List<({double temp, double rpm})> _recentTrace(
  SensorHistory history,
  String tempMetric,
  String rpmMetric,
) {
  final samples = history.samples;
  final recent = samples.length > 60
      ? samples.sublist(samples.length - 60)
      : samples;
  return [
    for (final s in recent)
      if (s[tempMetric] != null && s[rpmMetric] != null)
        (temp: s[tempMetric]!, rpm: s[rpmMetric]!),
  ];
}

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
    final metric = fanTempMetric(group.source);
    final raw = latest?[metric];
    final temp = gStatus?.temp ?? raw;
    final tempLabel = _tempLabel(
      strings,
      source: group.source,
      temp: temp,
      rawTemp: gStatus?.rawTemp ?? raw,
      unit: unit,
    );
    final trace = _recentTrace(history, metric, Metrics.alv2Rpm(index));

    void applyToAll() {
      controller.applyCurveToAll(index);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(f.appliedToAll(_groupLabel(strings, group)))),
      );
    }

    void updateGroup(FanGroupConfig g) => controller.updateGroup(g);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(WeSizes.unit * 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _groupsHeaderRow(
            strings: strings,
            group: group,
            onApplyAll: applyToAll,
          ),
          const SizedBox(height: WeSizes.unit * 1.5),
          _groupTilesRow(
            config: config,
            present: present,
            latest: latest,
            selected: index,
            onGroupTap: (g) => setState(() => _selected = g),
            strings: strings,
          ),
          const SizedBox(height: WeSizes.unit * 2),
          _headerCard(
            index: index,
            group: group,
            rpm: rpm,
            status: gStatus,
            hubOk: status?.hubOk,
            onName: (n) => controller.updateGroup(
              group.copyWith(name: n.trim().isEmpty ? group.name : n.trim()),
            ),
            onSize: (s) => controller.updateGroup(group.copyWith(size: s)),
          ),
          const SizedBox(height: WeSizes.unit * 2),
          _speedCurveCard(
            strings: strings,
            group: group,
            temp: temp,
            rpm: rpm,
            status: gStatus,
            tempLabel: tempLabel,
            trace: trace,
            onPresetChanged: controller.updateGroup,
            onCurveChanged: (g) => controller.updateGroup(g, persist: false),
            onCommit: controller.persist,
          ),
          const SizedBox(height: WeSizes.unit * 2),
          _groupOptionsCard(
            strings: strings,
            group: group,
            latest: latest,
            unit: unit,
            onGroupChanged: updateGroup,
          ),
        ],
      ),
    );
  }

  /// Chart caption: source, temperature, and the raw reading when it differs
  /// from the filtered one. `null` without a temperature.
  String? _tempLabel(
    AppStrings strings, {
    required FanTempSource source,
    required double? temp,
    required double? rawTemp,
    required TemperatureUnit unit,
  }) {
    if (temp == null) return null;
    final differs = rawTemp != null && (rawTemp - temp).abs() >= .5;
    final now = differs
        ? ' ${strings.fans.nowTemperature(formatTemp(rawTemp, unit))}'
        : '';
    return '${_sourceLabel(strings, source)} ${formatTemp(temp, unit)}$now';
  }

  /// Display name of [g], falling back to the catalog's default group name.
  String _groupLabel(AppStrings strings, FanGroupConfig g) =>
      g.name.trim().isEmpty ? strings.common.groupName(g.group) : g.name;

  /// Short label of a curve preset in the UI.
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

  /// Label of a temperature source in the UI.
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

  /// Short label of a fan response mode in the UI.
  String _responseLabel(AppStrings strings, FanResponse r) => switch (r) {
    FanResponse.fast => strings.fans.responseFast,
    FanResponse.normal => strings.fans.responseNormal,
    FanResponse.smooth => strings.fans.responseSmooth,
  };

  /// Hint of a fan response mode in the UI.
  String _responseHint(AppStrings strings, FanResponse r) => switch (r) {
    FanResponse.fast => strings.fans.responseFastHint,
    FanResponse.normal => strings.fans.responseNormalHint,
    FanResponse.smooth => strings.fans.responseSmoothHint,
  };

  /// Row with the groups title and the "apply to all" action.
  Widget _groupsHeaderRow({
    required AppStrings strings,
    required FanGroupConfig group,
    required VoidCallback onApplyAll,
  }) {
    final f = strings.fans;
    final groupLabel = _groupLabel(strings, group);
    return Row(
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
          message: f.applyAllTooltip(groupLabel),
          child: FilledButton.tonalIcon(
            key: const ValueKey('opt-apply-all'),
            icon: const Icon(Icons.copy_all, size: 18),
            label: Text(f.applyAllLabel(groupLabel)),
            onPressed: onApplyAll,
          ),
        ),
      ],
    );
  }

  /// Row with one tile per hub group.
  Widget _groupTilesRow({
    required FansConfig config,
    required List<bool> present,
    required SensorSample? latest,
    required int selected,
    required void Function(int) onGroupTap,
    required AppStrings strings,
  }) {
    return Row(
      children: [
        for (var g = 0; g < fanGroupCount; g++) ...[
          if (g > 0) const SizedBox(width: WeSizes.unit * 2),
          Expanded(
            child: _GroupTile(
              config: config[g],
              rpm: latest?[Metrics.alv2Rpm(g)],
              hasFan: present[g],
              selected: g == selected,
              label: _groupLabel(strings, config[g]),
              onTap: () => onGroupTap(g),
            ),
          ),
        ],
      ],
    );
  }

  /// Card with the selected group: name, size, and live status.
  Widget _headerCard({
    required int index,
    required FanGroupConfig group,
    required double? rpm,
    required FanGroupStatus? status,
    required bool? hubOk,
    required ValueChanged<String> onName,
    required ValueChanged<FanSize> onSize,
  }) {
    return WeCard(
      child: _Header(
        key: ValueKey('header-$index'),
        group: group,
        rpm: rpm,
        status: status,
        hubOk: hubOk,
        onName: onName,
        onSize: onSize,
      ),
    );
  }

  /// Card with the speed curve: preset chips, editor, and drag hint.
  Widget _speedCurveCard({
    required AppStrings strings,
    required FanGroupConfig group,
    required double? temp,
    required double? rpm,
    required FanGroupStatus? status,
    required String? tempLabel,
    required List<({double temp, double rpm})> trace,
    required ValueChanged<FanGroupConfig> onPresetChanged,
    required ValueChanged<FanGroupConfig> onCurveChanged,
    required VoidCallback onCommit,
  }) {
    final f = strings.fans;
    return WeCard(
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
                  onSelected: (_) => onPresetChanged(group.copyWith(preset: p)),
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
              duty: status?.duty,
              tempLabel: tempLabel,
              trace: trace,
            ),
            onChanged: onCurveChanged,
            onCommit: onCommit,
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
    );
  }

  /// Card with the group options: start/stop, temperature source, response.
  Widget _groupOptionsCard({
    required AppStrings strings,
    required FanGroupConfig group,
    required SensorSample? latest,
    required TemperatureUnit unit,
    required void Function(FanGroupConfig) onGroupChanged,
  }) {
    final f = strings.fans;
    final sourceOptions =
        <({FanTempSource source, String label, String value})>[
          for (final s in FanTempSource.values)
            if (!s.isBoard ||
                s == group.source ||
                latest?[fanTempMetric(s)] != null)
              (
                source: s,
                label: _sourceMenuLabel(strings, s),
                value: formatTemp(latest?[fanTempMetric(s)], unit),
              ),
        ];
    return WeCard(
      title: f.groupOptions,
      child: Column(
        children: [
          SettingRow(
            title: f.startStop,
            subtitle: Text(f.startStopHint),
            control: Switch(
              key: const ValueKey('opt-startstop'),
              value: group.startStop,
              onChanged: (v) => onGroupChanged(group.copyWith(startStop: v)),
            ),
          ),
          const Divider(),
          SettingRow(
            title: f.temperatureSource,
            subtitle: Text(f.temperatureSourceHint),
            control: _SourcePicker(
              key: const ValueKey('opt-source'),
              selected: group.source,
              options: sourceOptions,
              onChanged: (FanTempSource? s) {
                if (s != null) onGroupChanged(group.copyWith(source: s));
              },
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
              onSelectionChanged: (r) =>
                  onGroupChanged(group.copyWith(response: r.first)),
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
    required this.options,
    required this.onChanged,
  });

  final FanTempSource selected;
  final List<({FanTempSource source, String label, String value})> options;
  final ValueChanged<FanTempSource> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<FanTempSource>(
      value: selected,
      underline: const SizedBox.shrink(),
      borderRadius: BorderRadius.circular(WeSizes.radius),
      items: [
        for (final o in options)
          DropdownMenuItem(
            value: o.source,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(o.label),
                const SizedBox(width: WeSizes.unit * 1.5),
                Text(
                  o.value,
                  style: const TextStyle(color: WeColors.muted, fontSize: 12.5),
                ),
              ],
            ),
          ),
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
    required this.label,
    required this.onTap,
  });

  final FanGroupConfig config;
  final double? rpm;
  final bool hasFan;
  final bool selected;
  final String label;
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
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      '${config.size.diameterMm} mm',
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
