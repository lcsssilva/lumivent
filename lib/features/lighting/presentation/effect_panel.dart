// Right column (canvas mode): global effect controls generated from the
// `EffectParam` declarations, plus the fixed-color panel.
//
// Installed HTML effects generate the same controls from their
// `<meta property>` tags (plan §5.5).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/theme.dart';
import '../../../core/ui/widgets.dart';
import '../application/effects_controller.dart';
import '../application/lighting_controller.dart';
import '../application/html_effect_runner.dart';
import '../domain/effect_compat.dart';
import '../domain/effect_meta.dart';
import '../domain/hardware_equivalents.dart';
import '../domain/installed_effect.dart';
import '../domain/light_device.dart';
import '../domain/native_effects.dart';
import '../domain/rgb.dart';
import 'color_picker.dart';
import 'labels.dart';
import 'panel_controls.dart';

final _hueGradient = LinearGradient(
  colors: [for (var i = 0; i <= 6; i++) toColor(Rgb.fromHsv(i * 60.0, 1, 1))],
);

class EffectPanel extends ConsumerWidget {
  const EffectPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(lightingProvider);
    final effect = nativeEffectById(cfg.effectId);
    if (effect == null) {
      if (htmlEffectSlugOf(cfg.effectId) == null) {
        return const WeCard(
          flat: true,
          title: 'Efeito',
          child: Text('Este efeito não tem controles disponíveis.'),
        );
      }
      return _HtmlEffectPanel(effectId: cfg.effectId);
    }
    final values = cfg.effectValuesFor()!;
    void set(String key, Object v) => ref
        .read(lightingProvider.notifier)
        .update((c) => c.withEffectValue(effect.id, key, v));
    final fixedSpeed = firmwareSpeedFixed(cfg);

    return WeCard(
      flat: true,
      title: 'Efeito: ${effectLabel(effect.id, effect.name)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final p in effect.params)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ParamControl(
                key: ValueKey('param-${p.id}'),
                param: p,
                values: values,
                enabled: !(fixedSpeed && p.id == 'speed'),
                onChanged: (v) => set(p.id, v),
              ),
            ),
          if (fixedSpeed)
            const Text(
              'Velocidade fixa nas fans (modo do firmware).',
              key: Key('fixed-speed-notice'),
              style: TextStyle(color: WeColors.muted, fontSize: 12),
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
    return installed.when(
      loading: () => const WeCard(
        flat: true,
        title: 'Efeito',
        child: Text('Carregando efeitos instalados…'),
      ),
      error: (e, _) => WeCard(
        flat: true,
        title: 'Efeito',
        child: Text('Não foi possível ler a biblioteca: $e'),
      ),
      data: (effects) {
        final effect = effects.where((e) => e.id == slug).firstOrNull;
        if (effect == null) {
          return const WeCard(
            flat: true,
            title: 'Efeito',
            child: Text(
              'Este efeito não está instalado. Importe-o na aba Explore.',
            ),
          );
        }
        return WeCard(
          flat: true,
          title: 'Efeito: ${effect.title}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SupportLine(effect: effect),
              if (status.effectId == effectId && status.error != null) ...[
                const SizedBox(height: 8),
                Text(
                  status.error!,
                  key: const ValueKey('html-effect-status'),
                  style: const TextStyle(color: WeColors.warn, fontSize: 12),
                ),
              ],
              if (status.effectId == effectId && status.running) ...[
                const SizedBox(height: 8),
                Text(
                  '${status.fps.toStringAsFixed(0)} fps · '
                  '${status.frameMs.toStringAsFixed(1)} ms/quadro',
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
            effect.compatibility.issues.isEmpty
                ? effect.compatibility.label
                : '${effect.compatibility.label}: '
                      '${effect.compatibility.issues.join(', ')}',
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
    final cfg = ref.watch(lightingProvider);
    final raw = cfg.effectValues[cfg.effectId] ?? const <String, Object?>{};
    final params = [for (final p in effect.source.properties) ?_paramOf(p)];
    final values = EffectValues(params, raw);
    void set(String key, Object v) => ref
        .read(lightingProvider.notifier)
        .update((c) => c.withEffectValue(cfg.effectId, key, v));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final p in params)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ParamControl(
              key: ValueKey('param-${p.id}'),
              param: p,
              values: values,
              onChanged: (v) => set(p.id, v),
            ),
          ),
        for (final p in effect.source.properties)
          if (p.type == 'textfield' || p.type == 'sensor')
            Padding(
              key: ValueKey('param-${p.name}'),
              padding: const EdgeInsets.only(bottom: 8),
              child: PanelRow(
                label: p.label ?? p.name,
                control: SizedBox(
                  width: 150,
                  child: TextFormField(
                    initialValue: raw[p.name] is String
                        ? raw[p.name] as String
                        : '${p.initialValue ?? ''}',
                    decoration: const InputDecoration(isDense: true),
                    onFieldSubmitted: (v) => set(p.name, v),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

/// `EffectProperty` → the control declaration the panel already draws.
EffectParam? _paramOf(EffectProperty p) {
  switch (p.type) {
    case 'number':
      final lo = (p.min ?? 0).toDouble();
      final hi = (p.max ?? 100).toDouble();
      final def = p.initialValue is num
          ? (p.initialValue as num).toDouble()
          : lo;
      return EffectParam.number(
        p.name,
        p.label ?? p.name,
        min: lo,
        max: hi <= lo ? lo + 1 : hi,
        defaultValue: def.clamp(lo, hi <= lo ? lo + 1 : hi),
      );
    case 'hue':
      final def = p.initialValue is num
          ? (p.initialValue as num).toDouble()
          : 0.0;
      return EffectParam.hue(p.name, p.label ?? p.name, defaultValue: def);
    case 'color':
      final def = p.resolve(null);
      return EffectParam.color(
        p.name,
        p.label ?? p.name,
        defaultValue: def is String ? def : '#FFFFFF',
      );
    case 'boolean':
      return EffectParam.boolean(
        p.name,
        p.label ?? p.name,
        defaultValue: p.resolve(null) == true,
      );
    case 'combobox':
      final options = p.values;
      final def = p.resolve(null);
      return EffectParam.combobox(
        p.name,
        p.label ?? p.name,
        options: options,
        defaultValue: def is String && options.contains(def)
            ? def
            : (options.isEmpty ? '' : options.first),
      );
    default:
      return null;
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
    final p = param;
    final label = paramLabel(p.id, p.label);
    switch (p.type) {
      case EffectParamType.number:
        final v = values.number(p.id);
        return PanelSlider(
          label: label,
          valueText: v.round().toString(),
          value: v,
          min: p.min!,
          max: p.max!,
          enabled: enabled,
          onChanged: onChanged,
        );
      case EffectParamType.hue:
        final v = values.number(p.id);
        return PanelSlider(
          label: label,
          valueText: '${v.round()}°',
          value: v,
          min: 0,
          max: 360,
          background: _hueGradient,
          onChanged: onChanged,
        );
      case EffectParamType.color:
        return PanelRow(
          label: label,
          control: ColorSwatchButton(
            color: values.color(p.id),
            onChanged: (c) => onChanged(c.toHex()),
          ),
        );
      case EffectParamType.boolean:
        return PanelRow(
          label: label,
          control: Switch(value: values.boolean(p.id), onChanged: onChanged),
        );
      case EffectParamType.combobox:
        return PanelRow(
          label: label,
          control: PanelDropdown<String>(
            value: values.option(p.id),
            items: p.options,
            labelOf: (s) => s,
            onChanged: onChanged,
          ),
        );
    }
  }
}

/// Fixed-color panel for one device.
class FixedColorPanel extends ConsumerWidget {
  const FixedColorPanel({super.key, required this.id});
  final LightDeviceId id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(lightingProvider.select((c) => c.device(id)));
    return WeCard(
      flat: true,
      title: 'Cor fixa · ${deviceLabel(id, ref.watch(fanGroupNamesProvider))}',
      child: ColorPicker(
        color: cfg.fixedColor,
        onChanged: (c) => ref
            .read(lightingProvider.notifier)
            .update(
              (s) => s.withDevice(id, s.device(id).copyWith(fixedColor: c)),
            ),
      ),
    );
  }
}
