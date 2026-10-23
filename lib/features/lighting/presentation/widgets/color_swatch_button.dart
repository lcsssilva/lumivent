import 'package:flutter/material.dart';

import '../../../../core/ui/we_colors.dart';
import '../../domain/rgb.dart';
import 'color_picker.dart';
import '../rgb_color.dart';

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
