import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/app_strings.dart';
import '../../../../core/i18n/app_strings_scope.dart';
import '../../../../core/ui/we_colors.dart';
import '../../../../core/ui/we_card.dart';
import '../../application/effects/html_effect_runner.dart';
import '../../application/effects/html_effect_status.dart';
import '../../domain/effects/installed_effect.dart';
import '../../domain/config/lighting_config.dart';
import '../lighting_labels.dart';
import 'effect_support_line.dart';
import 'html_effect_controls.dart';

/// Controls of an installed HTML effect, generated from its metadata.
class HtmlEffectPanel extends StatelessWidget {
  const HtmlEffectPanel({
    super.key,
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
              EffectSupportLine(effect: effect),
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
              HtmlEffectControls(
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

String _htmlIssue(AppStrings strings, HtmlEffectStatus status) {
  final l = strings.lighting;
  return switch (status.issue) {
    HtmlEffectIssue.loadFailed => l.effectLoadFailed(status.error ?? ''),
    HtmlEffectIssue.paused => l.effectPaused(status.slowFrameMs),
    HtmlEffectIssue.unsupported => l.effectUnsupported(
      [
        for (final feature in status.missingFeatures)
          effectIssueLabel(strings, feature),
      ].join(', '),
    ),
    null => '',
  };
}
