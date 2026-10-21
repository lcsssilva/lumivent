import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/theme.dart';
import '../../../core/ui/widgets.dart';
import '../application/effects_controller.dart';
import '../application/lighting_controller.dart';
import '../application/html_effect_runner.dart';
import '../domain/led_layout.dart';
import '../domain/light_device.dart';
import '../domain/native_effects.dart';
import 'device_list.dart';
import 'effect_panel.dart';
import 'hardware_panels.dart';
import 'labels.dart';
import 'led_canvas.dart';

/// Lighting: devices in a horizontal strip on top, and a single card with the
/// canvas, the effect library, and the controls for the selected device or
/// global effect.
class LightingPage extends ConsumerStatefulWidget {
  const LightingPage({super.key});

  @override
  ConsumerState<LightingPage> createState() => _LightingPageState();
}

class _LightingPageState extends ConsumerState<LightingPage>
    with SingleTickerProviderStateMixin {
  static const _frame = Duration(milliseconds: 33);

  final _time = ValueNotifier<double>(0);
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  LightDeviceId? _selected;

  @override
  void initState() {
    super.initState();
    // createTicker follows TickerMode, so it stops while the page is hidden.
    _ticker = createTicker((elapsed) {
      if (elapsed - _last < _frame) return;
      _last = elapsed;
      _time.value = elapsed.inMicroseconds / 1e6;
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  Widget _rightPanel(LightDeviceId? sel) {
    if (sel == null) return const EffectPanel();
    final mode = ref.watch(lightingProvider.select((c) => c.device(sel).mode));
    return switch (mode) {
      LightMode.canvas => const EffectPanel(),
      LightMode.fixed => FixedColorPanel(id: sel),
      LightMode.hardware =>
        sel.isFan
            ? FanHardwarePanel(id: sel)
            : sel == LightDeviceId.motherboard
            ? const BoardHardwarePanel()
            : sel == LightDeviceId.gpu
            ? const GpuHardwarePanel()
            : const EffectPanel(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final cfg = ref.watch(lightingProvider);
    final installed = ref.watch(installedEffectsProvider).value ?? const [];
    final controller = ref.read(lightingProvider.notifier);
    const gap = WeSizes.unit * 2;

    return Padding(
      padding: const EdgeInsets.all(WeSizes.unit * 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (cfg.argbOff) ...[
            Container(
              key: const ValueKey('argb-off-banner'),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: WeColors.warn.withValues(alpha: .1),
                border: Border.all(color: WeColors.warn.withValues(alpha: .4)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: WeColors.warn,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Todos os ARGB estão desligados')),
                  TextButton(
                    key: const ValueKey('argb-on'),
                    onPressed: () => controller.setArgbOff(false),
                    child: const Text('Ligar'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: gap),
          ],
          WeCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text(
                      'Brilho',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Expanded(
                      child: Slider(
                        key: const ValueKey('global-brightness'),
                        value: cfg.brightness.clamp(0.0, 1.0),
                        onChanged: (v) =>
                            controller.update((c) => c.copyWith(brightness: v)),
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child: Text('${(cfg.brightness * 100).round()} %'),
                    ),
                    const SizedBox(width: gap),
                    const Text('Apagar ao suspender ou desligar'),
                    const SizedBox(width: 8),
                    Switch(
                      key: const ValueKey('off-on-sleep'),
                      value: cfg.offOnSleep,
                      onChanged: (v) =>
                          controller.update((c) => c.copyWith(offOnSleep: v)),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Usar os efeitos do próprio hardware quando possível',
                      ),
                    ),
                    Tooltip(
                      message:
                          'Fans e placa-mãe animam o efeito no próprio firmware, '
                          'com movimento mais suave. A fase entre os dispositivos '
                          'pode não ficar idêntica. Nos efeitos sem equivalente, '
                          'e sem esta opção, as fans recebem 2 quadros por '
                          'segundo: mais rápido, a velocidade delas oscila.',
                      child: const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: WeColors.muted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      key: const ValueKey('auto-hardware'),
                      value: cfg.autoHardware,
                      onChanged: (v) =>
                          controller.update((c) => c.copyWith(autoHardware: v)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: gap),
          DeviceList(
            selected: _selected,
            onSelect: (id) => setState(() => _selected = id),
          ),
          const SizedBox(height: gap),
          Expanded(
            child: WeCard(
              title: 'Canvas $canvasWidth×$canvasHeight',
              // Flexible so the card body takes the remaining height and the
              // canvas can size itself; the card is inside an Expanded.
              child: Flexible(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, box) {
                          // The library never takes more than half of the body,
                          // so the canvas stays visible in short windows.
                          final libMax = ((box.maxHeight - gap) * .5).clamp(
                            0.0,
                            170.0,
                          );
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Align(
                                  alignment: Alignment.topLeft,
                                  child: AspectRatio(
                                    aspectRatio: canvasWidth / canvasHeight,
                                    child: LedCanvas(
                                      config: cfg,
                                      time: _time,
                                      frame: ref.watch(
                                        htmlEffectFramesProvider,
                                      ),
                                      selected: _selected,
                                      onSelect: (id) =>
                                          setState(() => _selected = id),
                                      onPlace: (id, rect) => controller.update(
                                        (c) => c.withDevice(
                                          id,
                                          c
                                              .device(id)
                                              .copyWith(placement: rect),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: gap),
                              ConstrainedBox(
                                constraints: BoxConstraints(maxHeight: libMax),
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      const Text(
                                        'Biblioteca de efeitos',
                                        style: TextStyle(
                                          color: WeColors.muted,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          for (final e in nativeEffects)
                                            ChoiceChip(
                                              key: ValueKey('effect-${e.id}'),
                                              label: Text(
                                                effectLabel(e.id, e.name),
                                              ),
                                              selected: cfg.effectId == e.id,
                                              onSelected: (_) =>
                                                  controller.update(
                                                    (c) => c.copyWith(
                                                      effectId: e.id,
                                                    ),
                                                  ),
                                            ),
                                          for (final e in installed)
                                            ChoiceChip(
                                              key: ValueKey(
                                                'effect-${e.effectId}',
                                              ),
                                              label: Text(e.title),
                                              selected:
                                                  cfg.effectId == e.effectId,
                                              onSelected: e.canRun
                                                  ? (_) => controller.update(
                                                      (c) => c.copyWith(
                                                        effectId: e.effectId,
                                                      ),
                                                    )
                                                  : null,
                                            ),
                                        ],
                                      ),
                                      if (installed.isEmpty) ...[
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Importe efeitos HTML na aba '
                                          'Explore.',
                                          key: Key('no-installed-effects'),
                                          style: TextStyle(
                                            color: WeColors.muted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: gap),
                    SizedBox(
                      width: 340,
                      child: SingleChildScrollView(
                        child: _rightPanel(_selected),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
