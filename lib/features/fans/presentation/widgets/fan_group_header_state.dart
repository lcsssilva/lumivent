part of 'fan_group_header.dart';

class _FanGroupHeaderState extends State<FanGroupHeader> {
  late final _controller = TextEditingController(text: widget.group.name);
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _commit();
    });
  }

  @override
  void didUpdateWidget(FanGroupHeader old) {
    super.didUpdateWidget(old);
    if (!_focus.hasFocus && _controller.text != widget.group.name) {
      _controller.text = widget.group.name;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _commit() {
    final t = _controller.text.trim();
    if (t.isEmpty) {
      _controller.text = widget.group.name;
    } else if (t != widget.group.name) {
      widget.onName(t);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final f = strings.fans;
    final s = widget.status;
    final pills = <Widget>[
      if (s != null && s.temp == null)
        StatusPill(label: f.noTemperature, color: WeColors.warn),
      if (widget.hubOk == false)
        StatusPill(label: f.hubUnavailable, color: WeColors.danger),
    ];
    Widget stat(String label, String value) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: WeColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ],
    );
    return Wrap(
      spacing: WeSizes.unit * 3,
      runSpacing: WeSizes.unit * 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 220,
          child: TextField(
            key: const ValueKey('group-name'),
            controller: _controller,
            focusNode: _focus,
            maxLength: 24,
            decoration: InputDecoration(
              labelText: f.groupName,
              hintText: strings.common.groupName(widget.group.group),
              isDense: true,
              counterText: '',
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _commit(),
          ),
        ),
        SegmentedButton<FanSize>(
          key: const ValueKey('group-size'),
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: FanSize.mm120, label: Text('120 mm')),
            ButtonSegment(value: FanSize.mm140, label: Text('140 mm')),
          ],
          selected: {widget.group.size},
          onSelectionChanged: (v) => widget.onSize(v.first),
        ),
        stat(
          f.currentRpm,
          widget.rpm == null
              ? '—'
              : '${strings.grouped(widget.rpm!.round())} RPM',
        ),
        stat(f.duty, s?.duty == null ? '—' : '${s!.duty} %'),
        stat(
          f.target,
          s?.targetRpm == null ? '—' : '${strings.grouped(s!.targetRpm!)} RPM',
        ),
        ...pills,
      ],
    );
  }
}
