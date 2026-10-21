// Small controls shared by the lighting side panels.

import 'package:flutter/material.dart';

import '../../../core/ui/theme.dart';
import '../domain/rgb.dart';
import 'color_picker.dart';

Color toColor(Rgb c) => Color.fromARGB(255, c.r, c.g, c.b);

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

/// Row with a label on the left and a control on the right.
class PanelRow extends StatelessWidget {
  const PanelRow({super.key, required this.label, required this.control});
  final String label;
  final Widget control;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        control,
      ],
    ),
  );
}

/// Compact dropdown used by panels; a [value] not in [items] shows as empty.
class PanelDropdown<T> extends StatelessWidget {
  const PanelDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
  });
  final T? value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButton<T>(
    value: items.contains(value) ? value : null,
    isDense: true,
    underline: const SizedBox.shrink(),
    dropdownColor: WeColors.surface2,
    borderRadius: BorderRadius.circular(8),
    style: const TextStyle(fontSize: 13, color: WeColors.text),
    items: [
      for (final i in items)
        DropdownMenuItem<T>(value: i, child: Text(labelOf(i))),
    ],
    onChanged: (v) {
      if (v != null) onChanged(v);
    },
  );
}

/// Color swatch that opens the color picker dialog.
class ColorSwatchButton extends StatelessWidget {
  const ColorSwatchButton({
    super.key,
    required this.color,
    required this.onChanged,
    this.size = 28,
  });
  final Rgb color;
  final ValueChanged<Rgb> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: color.toHex(),
    child: InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => showColorPickerDialog(context, color, onChanged),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: toColor(color),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: WeColors.border),
        ),
      ),
    ),
  );
}
