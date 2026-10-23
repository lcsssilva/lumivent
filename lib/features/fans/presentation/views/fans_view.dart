import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/app_strings.dart';
import '../../../../core/i18n/app_strings_scope.dart';
import '../../../../core/ui/setting_row.dart';
import '../../../../core/ui/we_card.dart';
import '../../../../core/ui/we_colors.dart';
import '../../../../core/ui/we_sizes.dart';
import '../../../monitoring/monitoring.dart';
import '../../domain/fan_curve.dart';
import '../../domain/fan_group.dart';
import '../../domain/fan_presets.dart';
import '../../domain/fan_response.dart';
import '../fans_labels.dart';
import '../view_models/fans_ui_state.dart';
import '../view_models/fans_view_model.dart';
import '../widgets/fan_curve_editor.dart';
import '../widgets/fan_curve_live.dart';
import '../widgets/fan_group_header.dart';
import '../widgets/fan_group_tile.dart';
import '../widgets/fan_source_picker.dart';

/// AL V2 fan speed: groups, presets, options, and curve editor.
class FansView extends ConsumerWidget {
  const FansView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = ref.watch(fansViewModelProvider);
    final viewModel = ref.read(fansViewModelProvider.notifier);
    final strings = context.strings;

    void applyToAll() {
      viewModel.applyCurveToAll();
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            strings.fans.appliedToAll(fanGroupLabel(strings, ui.group)),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(WeSizes.unit * 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _groupsHeaderRow(strings, ui, onApplyAll: applyToAll),
          const SizedBox(height: WeSizes.unit * 1.5),
          _groupTilesRow(strings, ui, onGroupTap: viewModel.selectGroup),
          const SizedBox(height: WeSizes.unit * 2),
          WeCard(
            child: FanGroupHeader(
              key: ValueKey('header-${ui.selectedIndex}'),
              group: ui.group,
              rpm: ui.rpm,
              status: ui.groupStatus,
              hubOk: ui.hubOk,
              onName: viewModel.renameGroup,
              onSize: viewModel.setSize,
            ),
          ),
          const SizedBox(height: WeSizes.unit * 2),
          _speedCurveCard(strings, ui, viewModel),
          const SizedBox(height: WeSizes.unit * 2),
          _groupOptionsCard(strings, ui, viewModel),
        ],
      ),
    );
  }

  /// Chart caption: source, temperature, and the raw reading when it differs
  /// from the filtered one. `null` without a temperature.
  String? _tempLabel(AppStrings strings, FansUiState ui) {
    final temp = ui.temperature;
    if (temp == null) return null;
    final unit = ui.temperatureUnit;
    final now = ui.showsRawTemperature
        ? ' ${strings.fans.nowTemperature(formatTemp(ui.rawTemperature, unit))}'
        : '';
    return '${fanSourceLabel(strings, ui.group.source)} '
        '${formatTemp(temp, unit)}$now';
  }

  /// Row with the groups title and the "apply to all" action.
  Widget _groupsHeaderRow(
    AppStrings strings,
    FansUiState ui, {
    required VoidCallback onApplyAll,
  }) {
    final f = strings.fans;
    final groupLabel = fanGroupLabel(strings, ui.group);
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
  Widget _groupTilesRow(
    AppStrings strings,
    FansUiState ui, {
    required ValueChanged<int> onGroupTap,
  }) {
    final present = ui.groupsWithFan;
    return Row(
      children: [
        for (var g = 0; g < fanGroupCount; g++) ...[
          if (g > 0) const SizedBox(width: WeSizes.unit * 2),
          Expanded(
            child: FanGroupTile(
              config: ui.config[g],
              rpm: ui.groupRpm(g),
              hasFan: present[g],
              selected: g == ui.selectedIndex,
              label: fanGroupLabel(strings, ui.config[g]),
              onTap: () => onGroupTap(g),
            ),
          ),
        ],
      ],
    );
  }

  /// Card with the speed curve: preset chips, editor, and drag hint.
  Widget _speedCurveCard(
    AppStrings strings,
    FansUiState ui,
    FansViewModel viewModel,
  ) {
    final f = strings.fans;
    final group = ui.group;
    return WeCard(
      title: f.speedCurve,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in FanPreset.values)
                ChoiceChip(
                  key: ValueKey('preset-${p.name}'),
                  label: Text(fanPresetLabel(strings, p)),
                  selected: group.preset == p,
                  showCheckmark: false,
                  onSelected: (_) => viewModel.setPreset(p),
                ),
            ],
          ),
          const SizedBox(height: WeSizes.unit * 2),
          FanCurveEditor(
            key: const ValueKey('fan-curve-editor'),
            group: group,
            live: FanCurveLive(
              temp: ui.temperature,
              rpm: ui.rpm,
              duty: ui.groupStatus?.duty,
              tempLabel: _tempLabel(strings, ui),
              trace: ui.trace,
            ),
            onChanged: viewModel.previewCurve,
            onCommit: viewModel.commitCurve,
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
  Widget _groupOptionsCard(
    AppStrings strings,
    FansUiState ui,
    FansViewModel viewModel,
  ) {
    final f = strings.fans;
    final group = ui.group;
    final unit = ui.temperatureUnit;
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
              onChanged: viewModel.setStartStop,
            ),
          ),
          const Divider(),
          SettingRow(
            title: f.temperatureSource,
            subtitle: Text(f.temperatureSourceHint),
            control: FanSourcePicker(
              key: const ValueKey('opt-source'),
              selected: group.source,
              options: [
                for (final s in ui.sourceOptions)
                  (
                    source: s,
                    label: fanSourceMenuLabel(strings, s),
                    value: formatTemp(ui.sourceTemperature(s), unit),
                  ),
              ],
              onChanged: viewModel.setSource,
            ),
          ),
          const Divider(),
          SettingRow(
            title: f.temperatureResponse,
            subtitle: Text(fanResponseHint(strings, group.response)),
            control: SegmentedButton<FanResponse>(
              key: const ValueKey('opt-response'),
              showSelectedIcon: false,
              segments: [
                for (final r in FanResponse.values)
                  ButtonSegment(
                    value: r,
                    label: Text(fanResponseLabel(strings, r)),
                  ),
              ],
              selected: {group.response},
              onSelectionChanged: (r) => viewModel.setResponse(r.first),
            ),
          ),
        ],
      ),
    );
  }
}
