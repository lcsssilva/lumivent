part of 'lighting_view.dart';

class _LightingViewState extends ConsumerState<LightingView>
    with SingleTickerProviderStateMixin {
  static const _frame = Duration(milliseconds: 33);

  final _time = ValueNotifier<double>(0);
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  LightingViewModel get _viewModel =>
      ref.read(lightingViewModelProvider.notifier);

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

  Widget _argbBanner() {
    final l = context.strings.lighting;
    return Container(
      key: const ValueKey('argb-off-banner'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: WeColors.warn.withValues(alpha: .1),
        border: Border.all(color: WeColors.warn.withValues(alpha: .4)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, size: 16, color: WeColors.warn),
          const SizedBox(width: 8),
          Expanded(child: Text(l.allArgbOff)),
          TextButton(
            key: const ValueKey('argb-on'),
            onPressed: _viewModel.turnArgbOn,
            child: Text(l.turnOn),
          ),
        ],
      ),
    );
  }

  Widget _globalCard(LightingConfig cfg, AppStrings strings) {
    final l = strings.lighting;
    const gap = WeSizes.unit * 2;
    return WeCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                l.brightness,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Expanded(
                child: Slider(
                  key: const ValueKey('global-brightness'),
                  value: cfg.brightness.clamp(0.0, 1.0),
                  onChanged: _viewModel.setBrightness,
                ),
              ),
              SizedBox(
                width: 48,
                child: Text('${(cfg.brightness * 100).round()} %'),
              ),
              const SizedBox(width: gap),
              // Long in English; shrinks before the slider does.
              Flexible(
                child: Text(
                  l.offOnSleep,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                key: const ValueKey('off-on-sleep'),
                value: cfg.offOnSleep,
                onChanged: _viewModel.setOffOnSleep,
              ),
            ],
          ),
          Row(
            children: [
              Expanded(child: Text(l.useHardwareEffects)),
              Tooltip(
                message: l.hardwareEffectsHint,
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
                onChanged: _viewModel.setAutoHardware,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _canvasCard(LightingUiState ui, AppStrings strings) {
    final cfg = ui.config;
    final installed = ui.installedEffects;
    final selected = ui.selectedDevice;
    final l = strings.lighting;
    const gap = WeSizes.unit * 2;
    return WeCard(
      title: l.canvasSize(canvasWidth, canvasHeight),
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
                  final libMax = ((box.maxHeight - gap) * .5).clamp(0.0, 170.0);
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
                              frame: ui.frames,
                              selected: selected,
                              onSelect: _viewModel.selectDevice,
                              onPlace: _viewModel.placeDevice,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: gap),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: libMax),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                l.effectLibrary,
                                style: const TextStyle(
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
                                        effectLabel(strings, e.id, e.name),
                                      ),
                                      selected: cfg.effectId == e.id,
                                      onSelected: (_) =>
                                          _viewModel.selectEffect(e.id),
                                    ),
                                  for (final e in installed)
                                    ChoiceChip(
                                      key: ValueKey('effect-${e.effectId}'),
                                      label: Text(e.title),
                                      selected: cfg.effectId == e.effectId,
                                      onSelected: e.canRun
                                          ? (_) => _viewModel.selectEffect(
                                              e.effectId,
                                            )
                                          : null,
                                    ),
                                ],
                              ),
                              if (installed.isEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  l.importEffectsHint,
                                  key: const Key('no-installed-effects'),
                                  style: const TextStyle(
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
                child: LightingModePanel(
                  ui: ui,
                  onEdit: _viewModel.edit,
                  onIdentify: _viewModel.identify,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ui = ref.watch(lightingViewModelProvider);
    final cfg = ui.config;
    const gap = WeSizes.unit * 2;

    return Padding(
      padding: const EdgeInsets.all(WeSizes.unit * 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (cfg.argbOff) ...[_argbBanner(), const SizedBox(height: gap)],
          _globalCard(cfg, context.strings),
          const SizedBox(height: gap),
          DeviceList(
            ui: ui,
            onSelect: _viewModel.selectDevice,
            onEdit: _viewModel.edit,
          ),
          const SizedBox(height: gap),
          Expanded(child: _canvasCard(ui, context.strings)),
        ],
      ),
    );
  }
}
