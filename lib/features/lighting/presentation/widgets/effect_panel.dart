// Right column (canvas mode): global effect controls generated from the
// `EffectParam` declarations.
//
// Installed HTML effects generate the same controls from their
// `<meta property>` tags (plan §5.5).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/app_strings_scope.dart';
import '../../../../core/ui/we_colors.dart';
import '../../../../core/ui/we_card.dart';
import '../../application/effects/html_effect_status.dart';
import '../../domain/hardware_mode/hardware_equivalent.dart';
import '../../domain/effects/installed_effect.dart';
import '../../domain/config/lighting_config.dart';
import '../../domain/native_effects/native_effects.dart';
import '../lighting_labels.dart';
import 'effect_param_control.dart';
import 'html_effect_panel.dart';

class EffectPanel extends StatelessWidget {
  const EffectPanel({
    super.key,
    required this.config,
    required this.installedLibrary,
    required this.runnerStatus,
    required this.onEdit,
  });

  final LightingConfig config;

  /// The installed HTML effects as the library loads them.
  final AsyncValue<List<InstalledEffect>> installedLibrary;

  /// Status of the HTML effect being rendered.
  final HtmlEffectStatus runnerStatus;
  final ValueChanged<LightingConfigEdit> onEdit;

  @override
  Widget build(BuildContext context) {
    final effect = nativeEffectById(config.effectId);
    final strings = context.strings;
    final l = strings.lighting;
    if (effect == null) {
      if (htmlEffectSlugOf(config.effectId) == null) {
        return WeCard(flat: true, title: l.effect, child: Text(l.noControls));
      }
      return HtmlEffectPanel(
        effectId: config.effectId,
        config: config,
        installedLibrary: installedLibrary,
        status: runnerStatus,
        onEdit: onEdit,
      );
    }
    final values = config.effectValuesFor()!;
    void set(String key, Object v) =>
        onEdit((c) => c.withEffectValue(effect.id, key, v));
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
              child: EffectParamControl(
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
