part of 'color_picker.dart';

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
    final strings = context.strings;
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
                decoration: InputDecoration(
                  isDense: true,
                  counterText: '',
                  labelText: strings.lighting.hexadecimal,
                  border: const OutlineInputBorder(),
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
