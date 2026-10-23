import 'package:flutter/material.dart';

import '../../../../core/ui/we_colors.dart';

/// Label + value on one line, slider below. [background] paints a gradient
/// behind a transparent track (hue slider).
class PanelSlider extends StatelessWidget {
  const PanelSlider({
    super.key,
    required this.label,
    required this.valueText,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
    this.background,
    this.enabled = true,
  });
  final String label, valueText;
  final double value, min, max;
  final int? divisions;
  final Gradient? background;
  final ValueChanged<double> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final slider = Slider(
      value: value.clamp(min, max),
      min: min,
      max: max,
      divisions: divisions,
      onChanged: enabled ? onChanged : null,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
            Text(
              valueText,
              style: const TextStyle(color: WeColors.muted, fontSize: 12.5),
            ),
          ],
        ),
        if (background == null)
          slider
        else
          Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: background,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                ),
                child: slider,
              ),
            ],
          ),
      ],
    );
  }
}
