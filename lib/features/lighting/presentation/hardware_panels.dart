// Right column (hardware mode): firmware mode panel for AL V2 fan groups,
// per-zone effects for the motherboard, and the GPU effect panel.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/app_strings_scope.dart';
import '../../../core/ui/theme.dart';
import '../../../core/ui/widgets.dart';
import '../../devices/devices.dart';
import '../application/lighting_controller.dart';
import '../domain/led_layout.dart';
import '../domain/light_device.dart';
import '../domain/lighting_config.dart';
import 'labels.dart';
import 'panel_controls.dart';

List<String> _modeNames(Alv2LightScope scope) => [
  for (final m in Alv2LightMode.values)
    if (m.scope == scope) m.firmwareName,
];

/// Base names (`Runway`) of the merge modes, as stored in the config.
List<String> _mergeBases() => [
  for (final n in _modeNames(Alv2LightScope.merge))
    n.replaceFirst(RegExp(r'_Merge$'), ''),
];

/// Accepts `Runway` and `Runway_Merge`; returns a base name that is always in
/// the dropdown items (falls back to `Runway`).
String normalizeMergeMode(String name) {
  final base = name.replaceFirst(RegExp(r'_Merge$'), '');
  final bases = _mergeBases();
  return bases.contains(base) ? base : 'Runway';
}

/// Keeps the same effect when the scope changes (`Wave` <-> `Wave_Inner`).
String convertMode(String name, Alv2Scope to) {
  final base = name.split('_').first;
  final candidate = to == Alv2Scope.whole ? base : '${base}_Inner';
  return Alv2LightMode.byName(candidate) != null
      ? candidate
      : (to == Alv2Scope.whole ? 'StaticColor' : 'StaticColor_Inner');
}

class FanHardwarePanel extends ConsumerWidget {
  const FanHardwarePanel({super.key, required this.id});
  final LightDeviceId id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = id.hubGroup!;
    final cfg = ref.watch(lightingProvider);
    final controller = ref.read(lightingProvider.notifier);
    final hw = cfg.alv2Hardware[group];
    final qty = cfg.fanQuantity[group];
    final mode = Alv2LightMode.byName(hw.mode);
    final groupNames = ref.watch(fanGroupNamesProvider);
    final order = cfg.alv2MergeOrder;
    final strings = context.strings;
    final l = strings.lighting;

    void setHw(Alv2HardwareConfig Function(Alv2HardwareConfig) f) =>
        controller.update((c) {
          final list = [...c.alv2Hardware];
          list[group] = f(list[group]);
          return c.copyWith(alv2Hardware: list);
        });

    // The merge effect lives in slot 0 (the hub has no fans there). The config
    // stores the base name (`Runway`); the `_Merge` variant is only mapped here.
    final mergeBases = _mergeBases();
    final mergeBase = normalizeMergeMode(cfg.alv2MergeMode);
    final mergeMode = Alv2LightMode.byName('${mergeBase}_Merge');
    final merge = cfg.alv2Hardware[0];
    void setMerge(Alv2HardwareConfig Function(Alv2HardwareConfig) f) =>
        controller.update((c) {
          final list = [...c.alv2Hardware];
          list[0] = f(list[0]);
          return c.copyWith(alv2Hardware: list);
        });

    final scope = hw.scope == Alv2Scope.whole
        ? Alv2LightScope.whole
        : Alv2LightScope.inner;
    final names = _modeNames(scope);
    return WeCard(
      flat: true,
      title: l.hardwareTitle(deviceLabel(strings, id, groupNames)),
      trailing: OutlinedButton(
        key: const ValueKey('identify'),
        onPressed: () => controller.identify(group),
        child: Text(l.identify),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<Alv2Scope>(
            key: const ValueKey('hw-scope'),
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: Alv2Scope.whole,
                label: Text(l.wholeFan, style: const TextStyle(fontSize: 12)),
              ),
              ButtonSegment(
                value: Alv2Scope.innerOuter,
                label: Text(l.innerOuter, style: const TextStyle(fontSize: 12)),
              ),
            ],
            selected: {hw.scope},
            onSelectionChanged: (s) => setHw(
              (h) => h.copyWith(
                scope: s.first,
                mode: convertMode(h.mode, s.first),
              ),
            ),
          ),
          const SizedBox(height: 8),
          PanelRow(
            label: l.mode,
            control: PanelDropdown<String>(
              key: const ValueKey('hw-mode'),
              value: hw.mode,
              items: names,
              labelOf: firmwareModeLabel,
              onChanged: (m) => setHw((h) => h.copyWith(mode: m)),
            ),
          ),
          if (cfg.alv2Merge)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                l.mergeActive,
                style: const TextStyle(color: WeColors.warn, fontSize: 12),
              ),
            ),
          ..._effectControls(strings, mode, hw, setHw, 'hw'),
          const Divider(height: 24),
          PanelRow(
            label: l.fansInGroup,
            control: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  key: const ValueKey('fan-qty-minus'),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.remove),
                  onPressed: qty > 0
                      ? () => _setQty(controller, group, qty - 1)
                      : null,
                ),
                Text('$qty', key: const ValueKey('fan-qty')),
                IconButton(
                  key: const ValueKey('fan-qty-plus'),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.add),
                  onPressed: qty < maxFansPerGroup
                      ? () => _setQty(controller, group, qty + 1)
                      : null,
                ),
              ],
            ),
          ),
          PanelRow(
            label: l.mergeBetweenGroups,
            control: Switch(
              key: const ValueKey('hw-merge'),
              value: cfg.alv2Merge,
              onChanged: (v) =>
                  controller.update((c) => c.copyWith(alv2Merge: v)),
            ),
          ),
          if (cfg.alv2Merge) ...[
            PanelRow(
              label: l.mergeMode,
              control: PanelDropdown<String>(
                key: const ValueKey('hw-merge-mode'),
                value: mergeBase,
                items: mergeBases,
                labelOf: firmwareModeLabel,
                onChanged: (m) =>
                    controller.update((c) => c.copyWith(alv2MergeMode: m)),
              ),
            ),
            // Group 0 is empty and stays first; groups 1–3 follow the path
            // the merge should take, whatever port each chain is on.
            PanelRow(
              label: l.mergeOrder,
              control: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 1; i < order.length; i++)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$i. ${fanGroupName(strings, order[i], groupNames)}',
                          key: ValueKey('merge-order-$i'),
                          style: const TextStyle(fontSize: 13),
                        ),
                        IconButton(
                          key: ValueKey('merge-up-$i'),
                          visualDensity: VisualDensity.compact,
                          tooltip: strings.common.before,
                          icon: const Icon(Icons.arrow_upward, size: 18),
                          onPressed: i > 1
                              ? () => _moveMerge(controller, i, i - 1)
                              : null,
                        ),
                        IconButton(
                          key: ValueKey('merge-down-$i'),
                          visualDensity: VisualDensity.compact,
                          tooltip: strings.common.after,
                          icon: const Icon(Icons.arrow_downward, size: 18),
                          onPressed: i < order.length - 1
                              ? () => _moveMerge(controller, i, i + 1)
                              : null,
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                l.mergeShared,
                style: const TextStyle(color: WeColors.warn, fontSize: 12),
              ),
            ),
            ..._effectControls(strings, mergeMode, merge, setMerge, 'merge'),
          ],
        ],
      ),
    );
  }

  /// Speed, brightness, direction and colors of one hardware effect. `prefix`
  /// namespaces the widget keys (group panel vs merge).
  List<Widget> _effectControls(
    AppStrings strings,
    Alv2LightMode? mode,
    Alv2HardwareConfig hw,
    void Function(Alv2HardwareConfig Function(Alv2HardwareConfig)) setHw,
    String prefix,
  ) {
    final l = strings.lighting;
    final colorCount = mode?.colorCount ?? 0;
    final colors = [
      for (var i = 0; i < colorCount; i++)
        i < hw.colors.length
            ? hw.colors[i]
            : Alv2HardwareConfig.defaultColors[i %
                  Alv2HardwareConfig.defaultColors.length],
    ];
    return [
      if (mode?.hasSpeed ?? false)
        PanelSlider(
          label: l.speed,
          valueText: '${hw.speed + 1}/5',
          value: hw.speed.toDouble(),
          min: 0,
          max: 4,
          divisions: 4,
          onChanged: (v) => setHw((h) => h.copyWith(speed: v.round())),
        ),
      PanelSlider(
        label: l.brightness,
        valueText: '${hw.brightness + 1}/5',
        value: hw.brightness.toDouble(),
        min: 0,
        max: 4,
        divisions: 4,
        onChanged: (v) => setHw((h) => h.copyWith(brightness: v.round())),
      ),
      if (mode?.hasDirection ?? false)
        PanelRow(
          label: l.direction,
          control: SegmentedButton<bool>(
            key: ValueKey('$prefix-direction'),
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: false, label: Text(l.right)),
              ButtonSegment(value: true, label: Text(l.left)),
            ],
            selected: {hw.directionLeft},
            onSelectionChanged: (s) =>
                setHw((h) => h.copyWith(directionLeft: s.first)),
          ),
        ),
      if (colorCount > 0)
        PanelRow(
          label: l.colors,
          control: Wrap(
            spacing: 6,
            children: [
              for (var i = 0; i < colors.length; i++)
                ColorSwatchButton(
                  key: ValueKey('$prefix-color-$i'),
                  color: colors[i],
                  size: 24,
                  onChanged: (c) => setHw((h) {
                    final next = [...colors];
                    next[i] = c;
                    return h.copyWith(colors: next);
                  }),
                ),
            ],
          ),
        ),
    ];
  }

  /// Swaps positions [from] and [to] (1–3) of the merge order.
  void _moveMerge(LightingController c, int from, int to) => c.update((s) {
    final o = [...s.alv2MergeOrder];
    final g = o[from];
    o[from] = o[to];
    o[to] = g;
    return s.copyWith(alv2MergeOrder: o);
  });

  void _setQty(LightingController c, int group, int n) => c.update((s) {
    final q = [...s.fanQuantity];
    q[group] = n;
    return s.copyWith(fanQuantity: q);
  });
}

class GpuHardwarePanel extends ConsumerWidget {
  const GpuHardwarePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(lightingProvider);
    final controller = ref.read(lightingProvider.notifier);
    final strings = context.strings;
    final l = strings.lighting;
    final hw = cfg.gpuHardware;
    final colors = [
      for (var i = 0; i < hw.effect.colors; i++)
        i < hw.colors.length
            ? hw.colors[i]
            : GpuHardwareConfig.defaultColors[i %
                  GpuHardwareConfig.defaultColors.length],
    ];

    void setHw(GpuHardwareConfig Function(GpuHardwareConfig) f) =>
        controller.update((c) => c.copyWith(gpuHardware: f(c.gpuHardware)));

    return WeCard(
      flat: true,
      title: l.hardwareTitle(l.graphicsCard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PanelRow(
            label: l.mode,
            control: PanelDropdown<GpuEffect>(
              key: const ValueKey('gpu-mode'),
              value: hw.effect,
              items: GpuEffect.values,
              labelOf: (e) => gpuEffectLabel(strings, e),
              onChanged: (e) => setHw((h) => h.copyWith(effect: e)),
            ),
          ),
          if (hw.effect.hasSpeed)
            PanelSlider(
              label: l.speed,
              valueText: '${hw.speed}/10',
              value: hw.speed.toDouble(),
              min: 0,
              max: 10,
              divisions: 10,
              onChanged: (v) => setHw((h) => h.copyWith(speed: v.round())),
            ),
          if (hw.effect.hasBrightness)
            PanelSlider(
              label: l.brightness,
              valueText: '${hw.brightness}/10',
              value: hw.brightness.toDouble(),
              min: 0,
              max: 10,
              divisions: 10,
              onChanged: (v) => setHw((h) => h.copyWith(brightness: v.round())),
            ),
          if (hw.effect == GpuEffect.colorShift)
            PanelRow(
              label: l.colorsCount(8),
              control: Wrap(
                spacing: 6,
                children: [
                  for (var i = 0; i < colors.length; i++)
                    ColorSwatchButton(
                      key: ValueKey('gpu-color-$i'),
                      color: colors[i],
                      size: 24,
                      onChanged: (c) => setHw((h) {
                        final next = [...colors];
                        next[i] = c;
                        return h.copyWith(colors: next);
                      }),
                    ),
                ],
              ),
            )
          else if (hw.effect != GpuEffect.off)
            PanelRow(
              label: l.color,
              control: ColorSwatchButton(
                key: const ValueKey('gpu-color'),
                color: hw.color,
                onChanged: (c) => setHw((h) => h.copyWith(color: c)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l.gpuNote,
              style: const TextStyle(color: WeColors.muted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class BoardHardwarePanel extends ConsumerWidget {
  const BoardHardwarePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(lightingProvider);
    final controller = ref.read(lightingProvider.notifier);
    final strings = context.strings;
    final l = strings.lighting;

    void setZone(int z, BoardZoneConfig Function(BoardZoneConfig) f) =>
        controller.update(
          (c) =>
              c.copyWith(boardZones: {...c.boardZones, z: f(c.boardZones[z]!)}),
        );

    return WeCard(
      flat: true,
      title: l.boardHardwareTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final z in boardZoneIds) ...[
            Text(
              boardZoneLabel(strings, z),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            PanelRow(
              label: l.mode,
              control: PanelDropdown<BoardEffectMode>(
                key: ValueKey('board-mode-$z'),
                value: cfg.boardZones[z]!.mode,
                items: BoardEffectMode.values,
                labelOf: (m) => boardModeLabel(strings, m),
                onChanged: (m) => setZone(z, (b) => b.copyWith(mode: m)),
              ),
            ),
            PanelRow(
              label: l.color,
              control: ColorSwatchButton(
                key: ValueKey('board-color-$z'),
                color: cfg.boardZones[z]!.color,
                onChanged: (c) => setZone(z, (b) => b.copyWith(color: c)),
              ),
            ),
            PanelSlider(
              label: l.speed,
              valueText: '${cfg.boardZones[z]!.speed}',
              value: cfg.boardZones[z]!.speed.toDouble(),
              min: 0,
              max: 9,
              divisions: 9,
              onChanged: (v) => setZone(z, (b) => b.copyWith(speed: v.round())),
            ),
            PanelSlider(
              label: l.brightness,
              valueText: '${cfg.boardZones[z]!.brightness}',
              value: cfg.boardZones[z]!.brightness.toDouble(),
              min: 0,
              max: 9,
              divisions: 9,
              onChanged: (v) =>
                  setZone(z, (b) => b.copyWith(brightness: v.round())),
            ),
            if (z != boardZoneIds.last) const Divider(height: 24),
          ],
        ],
      ),
    );
  }
}
