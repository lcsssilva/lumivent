// Right column (canvas mode): global effect controls generated from the
// `EffectParam` declarations.
//
// Installed HTML effects generate the same controls from their
// `<meta property>` tags (plan §5.5).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/app_strings_scope.dart';
import '../../../core/ui/theme.dart';
import '../../../core/ui/we_card.dart';
import '../application/installed_effects_controller.dart';
import '../application/lighting_controller.dart';
import '../application/html_effect_runner.dart';
import '../domain/effect_compat.dart';
import '../domain/effect_property_param.dart';
import '../domain/hardware_equivalents.dart';
import '../domain/installed_effect.dart';
import '../domain/lighting_config.dart';
import '../domain/native_effects.dart';
import '../domain/rgb.dart';
import 'labels.dart';
import 'panel_controls.dart';

final _hueGradient = LinearGradient(
  colors: [for (var i = 0; i <= 6; i++) toColor(Rgb.fromHsv(i * 60.0, 1, 1))],
);

class EffectPanel extends ConsumerWidget {
  const EffectPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(lightingProvider);
    final effect = nativeEffectById(config.effectId);
    final strings = context.strings;
    final l = strings.lighting;
    if (effect == null) {
      if (htmlEffectSlugOf(config.effectId) == null) {
        return WeCard(flat: true, title: l.effect, child: Text(l.noControls));
      }
      return _HtmlEffectPanel(effectId: config.effectId);
    }
    final values = config.effectValuesFor()!;
    void set(String key, Object v) => ref
        .read(lightingProvider.notifier)
        .update((c) => c.withEffectValue(effect.id, key, v));
    final fixedSpeed = firmwareSpeedFixed(config);

    return WeCard(
      flat: true,
      title: l.effectTitle(effectLabel(strings, effect.id, effect.name)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final param in effect.params)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ParamControl(
                key: ValueKey('param-${param.id}'),
                param: param,
                values: values,
                enabled: !(fixedSpeed && param.id == 'speed'),
                onChanged: (v) => set(param.id, v),
              ),
            ),
          if (fixedSpeed)
            Text(
              l.fixedSpeedNotice,
              key: const Key('fixed-speed-notice'),
              style: const TextStyle(color: WeColors.muted, fontSize: 12),
            ),
        ],
      ),
    );
  }
}

/// Controls of an installed HTML effect, generated from its metadata.
class _HtmlEffectPanel extends ConsumerWidget {
  const _HtmlEffectPanel({required this.effectId});

  final String effectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final installed = ref.watch(installedEffectsProvider);
    final status = ref.watch(htmlEffectRunnerProvider);
    final slug = htmlEffectSlugOf(effectId);
    final strings = context.strings;
    final l = strings.lighting;
    return installed.when(
      loading: () =>
          WeCard(flat: true, title: l.effect, child: Text(l.loadingEffects)),
      error: (e, _) => WeCard(
        flat: true,
        title: l.effect,
        child: Text(l.libraryError('$e')),
      ),
      data: (effects) {
        final effect = effects.where((e) => e.id == slug).firstOrNull;
        if (effect == null) {
          return WeCard(
            flat: true,
            title: l.effect,
            child: Text(l.effectNotInstalled),
          );
        }
        return WeCard(
          flat: true,
          title: l.effectTitle(effect.title),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SupportLine(effect: effect),
              if (status.effectId == effectId && status.issue != null) ...[
                const SizedBox(height: 8),
                Text(
                  _htmlIssue(strings, status),
                  key: const ValueKey('html-effect-status'),
                  style: const TextStyle(color: WeColors.warn, fontSize: 12),
                ),
              ],
              if (status.effectId == effectId && status.running) ...[
                const SizedBox(height: 8),
                Text(
                  l.htmlStats(
                    strings.decimal(status.fps, 0),
                    strings.decimal(status.frameMs, 1),
                  ),
                  style: const TextStyle(color: WeColors.muted, fontSize: 12),
                ),
              ],
              const SizedBox(height: 8),
              _HtmlEffectControls(effect: effect),
            ],
          ),
        );
      },
    );
  }
}

class _SupportLine extends StatelessWidget {
  const _SupportLine({required this.effect});
  final InstalledEffect effect;

  @override
  Widget build(BuildContext context) {
    final color = switch (effect.compatibility.support) {
      EffectSupport.compatible => WeColors.ok,
      EffectSupport.partial => WeColors.warn,
      EffectSupport.unsupported => WeColors.danger,
    };
    final strings = context.strings;
    final l = strings.lighting;
    final label = switch (effect.compatibility.support) {
      EffectSupport.compatible => l.compatible,
      EffectSupport.partial => l.partial,
      EffectSupport.unsupported => l.unsupportedEffect,
    };
    final issues = [
      for (final i in effect.compatibility.issues) effectIssueLabel(strings, i),
    ];
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            issues.isEmpty ? label : '$label: ${issues.join(', ')}',
            style: TextStyle(color: color, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _HtmlEffectControls extends ConsumerWidget {
  const _HtmlEffectControls({required this.effect});
  final InstalledEffect effect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(lightingProvider);
    final raw =
        config.effectValues[config.effectId] ?? const <String, Object?>{};
    final params = [
      for (final property in effect.source.properties) ?property.toParam(),
    ];
    final values = EffectValues(params, raw);
    void set(String key, Object v) => ref
        .read(lightingProvider.notifier)
        .update((c) => c.withEffectValue(config.effectId, key, v));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final param in params)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ParamControl(
              key: ValueKey('param-${param.id}'),
              param: param,
              values: values,
              onChanged: (v) => set(param.id, v),
            ),
          ),
        for (final property in effect.source.properties)
          if (property.type == 'textfield' || property.type == 'sensor')
            Padding(
              key: ValueKey('param-${property.name}'),
              padding: const EdgeInsets.only(bottom: 8),
              child: PanelRow(
                label: property.label ?? property.name,
                control: SizedBox(
                  width: 150,
                  child: TextFormField(
                    initialValue: raw[property.name] is String
                        ? raw[property.name] as String
                        : '${property.initialValue ?? ''}',
                    decoration: const InputDecoration(isDense: true),
                    onFieldSubmitted: (v) => set(property.name, v),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

class _ParamControl extends StatelessWidget {
  const _ParamControl({
    super.key,
    required this.param,
    required this.values,
    required this.onChanged,
    this.enabled = true,
  });
  final EffectParam param;
  final EffectValues values;
  final ValueChanged<Object> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final label = paramLabel(strings, param.id, param.label);
    switch (param.type) {
      case EffectParamType.number:
        final value = values.number(param.id);
        return PanelSlider(
          label: label,
          valueText: value.round().toString(),
          value: value,
          min: param.min!,
          max: param.max!,
          enabled: enabled,
          onChanged: onChanged,
        );
      case EffectParamType.hue:
        final value = values.number(param.id);
        return PanelSlider(
          label: label,
          valueText: '${value.round()}°',
          value: value,
          min: 0,
          max: 360,
          background: _hueGradient,
          onChanged: onChanged,
        );
      case EffectParamType.color:
        return PanelRow(
          label: label,
          control: ColorSwatchButton(
            color: values.color(param.id),
            onChanged: (c) => onChanged(c.toHex()),
          ),
        );
      case EffectParamType.boolean:
        return PanelRow(
          label: label,
          control: Switch(
            value: values.boolean(param.id),
            onChanged: onChanged,
          ),
        );
      case EffectParamType.combobox:
        return PanelRow(
          label: label,
          control: PanelDropdown<String>(
            value: values.option(param.id),
            items: param.options,
            labelOf: (s) => strings.lighting.optionLabel(s),
            onChanged: onChanged,
          ),
        );
    }
  }
}

String _htmlIssue(AppStrings strings, HtmlEffectStatus status) {
  final l = strings.lighting;
  return switch (status.issue) {
    HtmlEffectIssue.loadFailed => l.effectLoadFailed(status.error ?? ''),
    HtmlEffectIssue.paused => l.effectPaused(status.slowFrameMs),
    HtmlEffectIssue.unsupported => l.effectUnsupported(
      [
        for (final feature in status.missingFeatures)
          effectIssueLabel(strings, feature),
      ].join(', '),
    ),
    null => '',
  };
}
