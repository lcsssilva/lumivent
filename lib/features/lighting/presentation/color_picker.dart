// Color picker without extra packages: saturation/value square, hue bar,
// hexadecimal field, and quick colors.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/ui/theme.dart';
import '../domain/rgb.dart';

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

Color _c(Rgb c) => Color.fromARGB(255, c.r, c.g, c.b);

/// Opens the picker in a dialog; [onChanged] is called live.
Future<void> showColorPickerDialog(
  BuildContext context,
  Rgb initial,
  ValueChanged<Rgb> onChanged,
) => showDialog<void>(
  context: context,
  builder: (ctx) => AlertDialog(
    backgroundColor: WeColors.surface,
    title: const Text('Escolher cor'),
    content: SizedBox(
      width: 280,
      child: ColorPicker(color: initial, onChanged: onChanged),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(ctx).pop(),
        child: const Text('Fechar'),
      ),
    ],
  ),
);

class ColorPicker extends StatefulWidget {
  const ColorPicker({super.key, required this.color, required this.onChanged});
  final Rgb color;
  final ValueChanged<Rgb> onChanged;

  @override
  State<ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  double _h = 0, _s = 1, _v = 1;
  final _hex = TextEditingController();

  Rgb get _rgb => Rgb.fromHsv(_h, _s, _v);

  @override
  void initState() {
    super.initState();
    _load(widget.color);
  }

  void _setHsv(Rgb c) {
    final (h, s, v) = rgbToHsv(c);
    _h = h;
    _s = s;
    _v = v;
  }

  void _load(Rgb c) {
    _setHsv(c);
    _hex.text = c.toHex();
  }

  @override
  void didUpdateWidget(ColorPicker old) {
    super.didUpdateWidget(old);
    // Keep the hue when the parent just echoes our own value back.
    if (widget.color != _rgb) _load(widget.color);
  }

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  void _emit({bool syncHex = true}) {
    if (syncHex) _hex.text = _rgb.toHex();
    widget.onChanged(_rgb);
  }

  void _pickSv(Offset p, Size size) {
    setState(() {
      _s = (p.dx / size.width).clamp(0.0, 1.0);
      _v = 1 - (p.dy / size.height).clamp(0.0, 1.0);
    });
    _emit();
  }

  void _pickHue(Offset p, Size size) {
    setState(() => _h = (p.dx / size.width).clamp(0.0, 1.0) * 360);
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, box) {
            final size = Size(box.maxWidth, 140);
            return GestureDetector(
              key: const ValueKey('picker-sv'),
              onPanDown: (d) => _pickSv(d.localPosition, size),
              onPanUpdate: (d) => _pickSv(d.localPosition, size),
              child: CustomPaint(size: size, painter: _SvPainter(_h, _s, _v)),
            );
          },
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, box) {
            final size = Size(box.maxWidth, 16);
            return GestureDetector(
              key: const ValueKey('picker-hue'),
              onPanDown: (d) => _pickHue(d.localPosition, size),
              onPanUpdate: (d) => _pickHue(d.localPosition, size),
              child: CustomPaint(size: size, painter: _HuePainter(_h)),
            );
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _c(_rgb),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: WeColors.border),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                key: const ValueKey('picker-hex'),
                controller: _hex,
                maxLength: 7,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[#0-9a-fA-F]')),
                ],
                decoration: const InputDecoration(
                  isDense: true,
                  counterText: '',
                  labelText: 'Hexadecimal',
                  border: OutlineInputBorder(),
                ),
                onChanged: (t) {
                  final c = Rgb.parse(t);
                  if (c == null || t.replaceAll('#', '').length < 6) return;
                  setState(() => _setHsv(c));
                  _emit(syncHex: false);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final q in quickColors)
              InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () {
                  setState(() => _load(q));
                  widget.onChanged(q);
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _c(q),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: WeColors.border),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _SvPainter extends CustomPainter {
  _SvPainter(this.h, this.s, this.v);
  final double h, s, v;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)));
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.white, _c(Rgb.fromHsv(h, 1, 1))],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black],
        ).createShader(rect),
    );
    canvas.restore();
    final p = Offset(s * size.width, (1 - v) * size.height);
    canvas.drawCircle(
      p,
      7,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white,
    );
    canvas.drawCircle(
      p,
      8.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.black54,
    );
  }

  @override
  bool shouldRepaint(_SvPainter o) => o.h != h || o.s != s || o.v != v;
}

class _HuePainter extends CustomPainter {
  _HuePainter(this.h);
  final double h;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()
        ..shader = LinearGradient(
          colors: [
            for (var i = 0; i <= 6; i++) _c(Rgb.fromHsv(i * 60.0, 1, 1)),
          ],
        ).createShader(rect),
    );
    final x = h / 360 * size.width;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x, size.height / 2),
          width: 6,
          height: size.height + 4,
        ),
        const Radius.circular(3),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_HuePainter o) => o.h != h;
}
