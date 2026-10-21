// Top strip: one item per lighting device (status, switch, mode) in a
// horizontal carousel. Items have a fixed width and scroll sideways, with
// arrow buttons and a scrollbar; a mouse drag also scrolls.

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/theme.dart';
import '../../../core/ui/widgets.dart';
import '../application/lighting_controller.dart';
import '../application/lighting_messages.dart';
import '../domain/hardware_equivalents.dart';
import '../domain/light_device.dart';
import 'labels.dart';
import 'panel_controls.dart';

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

    Widget arrow(IconData icon, String tooltip, bool enabled, int direction) =>
        IconButton(
          key: ValueKey(direction < 0 ? 'devices-prev' : 'devices-next'),
          tooltip: tooltip,
          onPressed: enabled ? () => _page(direction) : null,
          visualDensity: VisualDensity.compact,
          icon: Icon(icon, size: 20),
        );

    return WeCard(
      title: 'Dispositivos',
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          arrow(Icons.chevron_left, 'Dispositivos anteriores', _canBack, -1),
          arrow(Icons.chevron_right, 'Próximos dispositivos', _canNext, 1),
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

class DeviceItem extends ConsumerWidget {
  const DeviceItem({
    super.key,
    required this.id,
    required this.selected,
    required this.onTap,
  }) : super();
  final LightDeviceId id;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(lightingProvider.select((c) => c.device(id)));
    final status = ref.watch(
      lightingStatusProvider.select((s) => s?.devices[id]),
    );
    // Canvas device the engine hands to the firmware for the current effect.
    final auto = ref.watch(
      lightingProvider.select((c) => autoHardwareDevices(c).contains(id)),
    );
    final controller = ref.read(lightingProvider.notifier);
    final supported = id.isSupported;

    final (Color dot, String tip) = !supported
        ? (WeColors.muted, 'Não suportado')
        : switch (status?.state) {
            null => (WeColors.muted, 'Aguardando status do dispositivo'),
            LightOutputState.ok => (WeColors.ok, 'Funcionando'),
            LightOutputState.unavailable => (
              WeColors.danger,
              status!.detail ?? 'Dispositivo indisponível',
            ),
            LightOutputState.unsupported => (
              WeColors.muted,
              status!.detail ?? 'Não suportado',
            ),
          };

    return Opacity(
      opacity: supported ? 1 : .5,
      child: Container(
        key: ValueKey('device-${id.name}'),
        decoration: BoxDecoration(
          color: selected ? WeColors.accent.withValues(alpha: .12) : null,
          border: Border.all(
            color: selected ? WeColors.accent : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: supported ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Tooltip(
                      message: tip,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: StatusDot(
                          dot,
                          key: ValueKey('status-${id.name}'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        deviceLabel(id, ref.watch(fanGroupNamesProvider)),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    if (supported)
                      Transform.scale(
                        scale: .8,
                        child: Switch(
                          key: ValueKey('device-switch-${id.name}'),
                          value: cfg.enabled,
                          onChanged: (v) => controller.update(
                            (c) => c.withDevice(id, cfg.copyWith(enabled: v)),
                          ),
                        ),
                      ),
                  ],
                ),
                if (!supported)
                  const Padding(
                    padding: EdgeInsets.only(left: 24),
                    child: Text(
                      'Não suportado',
                      style: TextStyle(color: WeColors.muted, fontSize: 12),
                    ),
                  )
                else ...[
                  if (status?.state == LightOutputState.unavailable)
                    Padding(
                      padding: const EdgeInsets.only(left: 24, bottom: 2),
                      child: Text(
                        'Indisponível',
                        style: const TextStyle(
                          color: WeColors.danger,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  if (auto)
                    const Padding(
                      padding: EdgeInsets.only(left: 24, bottom: 2),
                      child: Text(
                        'Hardware (auto)',
                        key: Key('auto-badge'),
                        style: TextStyle(color: WeColors.muted, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 2),
                  // Full-width dropdown: the strip is narrow, so the mode must
                  // have the whole item width instead of sharing a row.
                  PanelDropdown<LightMode>(
                    key: ValueKey('device-mode-${id.name}'),
                    value: cfg.mode,
                    items: [
                      for (final m in LightMode.values)
                        if (id.accepts(m)) m,
                    ],
                    labelOf: modeLabel,
                    onChanged: (m) {
                      controller.update(
                        (c) => c.withDevice(id, cfg.copyWith(mode: m)),
                      );
                      onTap();
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
