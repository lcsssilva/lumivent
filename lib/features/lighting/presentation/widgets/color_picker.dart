// Color picker without extra packages: saturation/value square, hue bar,
// hexadecimal field, and quick colors.

import 'package:flutter/material.dart';

import '../rgb_color.dart';

import 'package:flutter/services.dart';

import '../../../../core/i18n/app_strings_scope.dart';
import '../../../../core/ui/we_colors.dart';
import '../../domain/rgb.dart';
import 'color_hue_painter.dart';
import 'color_sv_painter.dart';

part 'color_picker_state.dart';

/// (hue 0–360, saturation 0–1, value 0–1) of [c].
(double, double, double) rgbToHsv(Rgb c) {
  final r = c.r / 255, g = c.g / 255, b = c.b / 255;
  final mx = [r, g, b].reduce((a, b) => a > b ? a : b);
  final mn = [r, g, b].reduce((a, b) => a < b ? a : b);
  final d = mx - mn;
  var h = 0.0;
  if (d > 0) {
    if (mx == r) {
      h = 60 * (((g - b) / d) % 6);
    } else if (mx == g) {
      h = 60 * ((b - r) / d + 2);
    } else {
      h = 60 * ((r - g) / d + 4);
    }
  }
  return (h < 0 ? h + 360 : h, mx == 0 ? 0.0 : d / mx, mx);
}

const quickColors = [
  Rgb(255, 0, 0),
  Rgb(255, 128, 0),
  Rgb(255, 255, 0),
  Rgb(0, 255, 0),
  Rgb(0, 255, 255),
  Rgb(0, 0, 255),
  Rgb(160, 32, 240),
  Rgb(255, 0, 128),
  Rgb(255, 255, 255),
];

/// Opens the picker in a dialog; [onChanged] is called live.
Future<void> showColorPickerDialog(
  BuildContext context,
  Rgb initial,
  ValueChanged<Rgb> onChanged,
) => showDialog<void>(
  context: context,
  builder: (ctx) {
    final strings = ctx.strings;
    return AlertDialog(
      backgroundColor: WeColors.surface,
      title: Text(strings.lighting.chooseColor),
      content: SizedBox(
        width: 280,
        child: ColorPicker(color: initial, onChanged: onChanged),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(strings.common.close),
        ),
      ],
    );
  },
);

class ColorPicker extends StatefulWidget {
  const ColorPicker({super.key, required this.color, required this.onChanged});
  final Rgb color;
  final ValueChanged<Rgb> onChanged;

  @override
  State<ColorPicker> createState() => _ColorPickerState();
}
