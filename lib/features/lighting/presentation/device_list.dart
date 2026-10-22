// Top strip: one item per lighting device (status, switch, mode) in a
// horizontal carousel. Items have a fixed width and scroll sideways, with
// arrow buttons and a scrollbar; a mouse drag also scrolls.

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';

import '../../../core/i18n/app_strings_scope.dart';
import '../../../core/ui/we_card.dart';
import '../domain/light_device.dart';
import 'device_item.dart';

class DeviceList extends StatefulWidget {
  const DeviceList({super.key, required this.selected, required this.onSelect});
  final LightDeviceId? selected;
  final ValueChanged<LightDeviceId> onSelect;

  @override
  State<DeviceList> createState() => _DeviceListState();
}

class _DeviceListState extends State<DeviceList> {
  static const _gap = 8.0;
  static const _itemWidth = 220.0;
  static const _scrollbarRoom = 10.0;

  final _scroll = ScrollController();
  bool _canBack = false;
  bool _canNext = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_sync);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void didUpdateWidget(covariant DeviceList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final id = widget.selected;
    if (id != null && id != oldWidget.selected) _reveal(id);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Brings the selected item into view, e.g. when it was picked on the canvas.
  void _reveal(LightDeviceId id) {
    if (!_scroll.hasClients) return;
    final i = LightDeviceId.values.indexOf(id);
    if (i < 0) return;
    final p = _scroll.position;
    final start = i * (_itemWidth + _gap);
    final end = start + _itemWidth;
    final double target;
    if (start < p.pixels) {
      target = start;
    } else if (end > p.pixels + p.viewportDimension) {
      target = end - p.viewportDimension;
    } else {
      return;
    }
    _scroll.animateTo(
      target.clamp(0.0, p.maxScrollExtent),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  void _sync() {
    if (!mounted || !_scroll.hasClients) return;
    final p = _scroll.position;
    final back = p.pixels > .5;
    final next = p.pixels < p.maxScrollExtent - .5;
    if (back == _canBack && next == _canNext) return;
    setState(() {
      _canBack = back;
      _canNext = next;
    });
  }

  void _page(int direction) {
    if (!_scroll.hasClients) return;
    final p = _scroll.position;
    final step = (_itemWidth + _gap) * 3;
    final target = (p.pixels + direction * step).clamp(0.0, p.maxScrollExtent);
    _scroll.animateTo(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ids = LightDeviceId.values;
    final strings = context.strings;
    final l = strings.lighting;

    Widget arrow(IconData icon, String tooltip, bool enabled, int direction) =>
        IconButton(
          key: ValueKey(direction < 0 ? 'devices-prev' : 'devices-next'),
          tooltip: tooltip,
          onPressed: enabled ? () => _page(direction) : null,
          visualDensity: VisualDensity.compact,
          icon: Icon(icon, size: 20),
        );

    return WeCard(
      title: l.devices,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          arrow(Icons.chevron_left, l.previousDevices, _canBack, -1),
          arrow(Icons.chevron_right, l.nextDevices, _canNext, 1),
        ],
      ),
      child: ScrollConfiguration(
        // The carousel must also follow a mouse drag on desktop.
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: const {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
            PointerDeviceKind.stylus,
          },
          scrollbars: false,
        ),
        child: NotificationListener<ScrollMetricsNotification>(
          onNotification: (_) {
            _sync();
            return false;
          },
          child: Scrollbar(
            controller: _scroll,
            thumbVisibility: true,
            thickness: 4,
            child: SingleChildScrollView(
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: _scrollbarRoom),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (i, id) in ids.indexed) ...[
                    if (i > 0) const SizedBox(width: _gap),
                    SizedBox(
                      width: _itemWidth,
                      child: DeviceItem(
                        id: id,
                        selected: widget.selected == id,
                        onTap: () => widget.onSelect(id),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
