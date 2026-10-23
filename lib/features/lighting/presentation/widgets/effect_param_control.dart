import 'package:flutter/material.dart';

import '../../../../core/i18n/app_strings_scope.dart';
import '../../domain/effects/effect_param.dart';
import '../../domain/effects/effect_values.dart';
import '../../domain/rgb.dart';
import '../lighting_labels.dart';
import '../rgb_color.dart';
import 'panel_slider.dart';
import 'panel_row.dart';
import 'panel_dropdown.dart';
import 'color_swatch_button.dart';

class EffectParamControl extends StatelessWidget {
  const EffectParamControl({
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

final _hueGradient = LinearGradient(
  colors: [for (var i = 0; i <= 6; i++) toColor(Rgb.fromHsv(i * 60.0, 1, 1))],
);
