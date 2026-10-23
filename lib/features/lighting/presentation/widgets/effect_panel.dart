// Right column (canvas mode): global effect controls generated from the
// `EffectParam` declarations.
//
// Installed HTML effects generate the same controls from their
// `<meta property>` tags (plan §5.5).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/app_strings.dart';
import '../../../../core/i18n/app_strings_scope.dart';
import '../../../../core/ui/we_colors.dart';
import '../../../../core/ui/we_card.dart';
import '../../application/installed_effects_notifier.dart';
import '../../application/lighting_notifier.dart';
import '../../application/html_effect_runner.dart';
import '../../application/html_effect_status.dart';
import '../../domain/effect_compatibility.dart';
import '../../domain/effect_property_param.dart';
import '../../domain/hardware_equivalent.dart';
import '../../domain/installed_effect.dart';
import '../../domain/lighting_config.dart';
import '../../domain/native_effects.dart';
import '../../domain/effect_values.dart';
import '../../domain/rgb.dart';
import '../lighting_labels.dart';
import '../rgb_color.dart';
import 'panel_slider.dart';
import 'panel_row.dart';
import 'panel_dropdown.dart';
import 'color_swatch_button.dart';

part 'html_effect_panel.dart';
part 'support_line.dart';
part 'html_effect_controls.dart';
part 'param_control.dart';

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
