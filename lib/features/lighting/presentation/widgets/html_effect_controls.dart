import 'package:flutter/material.dart';

import '../../domain/effects/effect_property_param.dart';
import '../../domain/effects/installed_effect.dart';
import '../../domain/config/lighting_config.dart';
import '../../domain/effects/effect_values.dart';
import 'panel_row.dart';
import 'effect_param_control.dart';

class HtmlEffectControls extends StatelessWidget {
  const HtmlEffectControls({
    super.key,
    required this.effect,
    required this.config,
    required this.onEdit,
  });

  final InstalledEffect effect;
  final LightingConfig config;
  final ValueChanged<LightingConfigEdit> onEdit;

  @override
  Widget build(BuildContext context) {
    final raw =
        config.effectValues[config.effectId] ?? const <String, Object?>{};
    final params = [
      for (final property in effect.source.properties) ?property.toParam(),
    ];
    final values = EffectValues(params, raw);
    void set(String key, Object v) =>
        onEdit((c) => c.withEffectValue(config.effectId, key, v));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final param in params)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: EffectParamControl(
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
