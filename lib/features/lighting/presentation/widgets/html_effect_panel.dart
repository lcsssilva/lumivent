part of 'effect_panel.dart';

/// Controls of an installed HTML effect, generated from its metadata.
class _HtmlEffectPanel extends StatelessWidget {
  const _HtmlEffectPanel({
    required this.effectId,
    required this.config,
    required this.installedLibrary,
    required this.status,
    required this.onEdit,
  });

  final String effectId;
  final LightingConfig config;
  final AsyncValue<List<InstalledEffect>> installedLibrary;
  final HtmlEffectStatus status;
  final ValueChanged<LightingConfigEdit> onEdit;

  @override
  Widget build(BuildContext context) {
    final slug = htmlEffectSlugOf(effectId);
    final strings = context.strings;
    final l = strings.lighting;
    return installedLibrary.when(
      loading: () =>
          WeCard(flat: true, title: l.effect, child: Text(l.loadingEffects)),
      error: (e, _) => WeCard(
        flat: true,
        title: l.effect,
        child: Text(l.libraryError('$e')),
      ),
      data: (effects) {
        final effect = effects.where((e) => e.id == slug).firstOrNull;
        if (effect == null) {
          return WeCard(
            flat: true,
            title: l.effect,
            child: Text(l.effectNotInstalled),
          );
        }
        return WeCard(
          flat: true,
          title: l.effectTitle(effect.title),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SupportLine(effect: effect),
              if (status.effectId == effectId && status.issue != null) ...[
                const SizedBox(height: 8),
                Text(
                  _htmlIssue(strings, status),
                  key: const ValueKey('html-effect-status'),
                  style: const TextStyle(color: WeColors.warn, fontSize: 12),
                ),
              ],
              if (status.effectId == effectId && status.running) ...[
                const SizedBox(height: 8),
                Text(
                  l.htmlStats(
                    strings.decimal(status.fps, 0),
                    strings.decimal(status.frameMs, 1),
                  ),
                  style: const TextStyle(color: WeColors.muted, fontSize: 12),
                ),
              ],
              const SizedBox(height: 8),
              _HtmlEffectControls(
                effect: effect,
                config: config,
                onEdit: onEdit,
              ),
            ],
          ),
        );
      },
    );
  }
}
