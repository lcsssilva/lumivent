part of 'effect_panel.dart';

class _HtmlEffectControls extends ConsumerWidget {
  const _HtmlEffectControls({required this.effect});
  final InstalledEffect effect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(lightingProvider);
    final raw =
        config.effectValues[config.effectId] ?? const <String, Object?>{};
    final params = [
      for (final property in effect.source.properties) ?property.toParam(),
    ];
    final values = EffectValues(params, raw);
    void set(String key, Object v) => ref
        .read(lightingProvider.notifier)
        .update((c) => c.withEffectValue(config.effectId, key, v));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final param in params)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ParamControl(
              key: ValueKey('param-${param.id}'),
              param: param,
              values: values,
              onChanged: (v) => set(param.id, v),
            ),
          ),
        for (final property in effect.source.properties)
          if (property.type == 'textfield' || property.type == 'sensor')
            Padding(
              key: ValueKey('param-${property.name}'),
              padding: const EdgeInsets.only(bottom: 8),
              child: PanelRow(
                label: property.label ?? property.name,
                control: SizedBox(
                  width: 150,
                  child: TextFormField(
                    initialValue: raw[property.name] is String
                        ? raw[property.name] as String
                        : '${property.initialValue ?? ''}',
                    decoration: const InputDecoration(isDense: true),
                    onFieldSubmitted: (v) => set(property.name, v),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}
