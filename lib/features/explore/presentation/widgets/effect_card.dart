import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/i18n/app_strings_scope.dart';
import '../../../../core/ui/status_pill.dart';
import '../../../../core/ui/we_colors.dart';
import '../../../../core/ui/we_sizes.dart';
import '../../../lighting/lighting.dart';

part 'effect_thumbnail.dart';
part 'effect_tag.dart';

/// Installed-effect card in the Explore grid: thumbnail, compatibility,
/// metadata and the apply/remove actions.
class EffectCard extends StatelessWidget {
  const EffectCard({
    super.key,
    required this.effect,
    required this.applied,
    required this.thumbnail,
    required this.onApply,
    required this.onRemove,
  });

  final InstalledEffect effect;
  final bool applied;
  final Future<Uint8List?>? thumbnail;
  final VoidCallback? onApply;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final explore = strings.explore;
    final badgeColor = switch (effect.compatibility.support) {
      EffectSupport.compatible => WeColors.ok,
      EffectSupport.partial => WeColors.warn,
      EffectSupport.unsupported => WeColors.danger,
    };
    return Container(
      decoration: BoxDecoration(
        color: WeColors.surface,
        borderRadius: BorderRadius.circular(WeSizes.radius),
        border: Border.all(
          color: applied ? WeColors.accent : WeColors.border,
          width: applied ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _EffectThumbnail(effect: effect, bytes: thumbnail),
                Positioned(
                  left: 8,
                  top: 8,
                  child: StatusPill(
                    label: switch (effect.compatibility.support) {
                      EffectSupport.compatible => explore.compatible,
                      EffectSupport.partial => explore.partial,
                      EffectSupport.unsupported => explore.unsupported,
                    },
                    color: badgeColor,
                    background: WeColors.bg.withValues(alpha: .82),
                  ),
                ),
                if (applied)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: StatusPill(
                      label: explore.appliedBadge,
                      color: WeColors.accent,
                      background: WeColors.bg.withValues(alpha: .82),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    effect.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    effect.publisher ??
                        switch (effect.origin) {
                          EffectOrigin.file => explore.originFile,
                          EffectOrigin.folder => explore.originFolder,
                          EffectOrigin.zip => explore.originZip,
                          EffectOrigin.windowsCache =>
                            explore.originWindowsCache,
                        },
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: WeColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 22,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final tag in effect.tags.take(4))
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: _EffectTag(text: tag),
                          ),
                      ],
                    ),
                  ),
                  if (!effect.canRun) ...[
                    const SizedBox(height: 4),
                    Text(
                      explore.requires(
                        [
                          for (final issue in effect.compatibility.issues)
                            effectIssueLabel(strings, issue),
                        ].join(', '),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: WeColors.danger,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: applied
                            ? OutlinedButton.icon(
                                onPressed: null,
                                icon: const Icon(
                                  Icons.check_circle_outline,
                                  size: 16,
                                ),
                                label: Text(explore.applied),
                              )
                            : FilledButton.tonalIcon(
                                onPressed: onApply,
                                icon: const Icon(Icons.play_arrow, size: 18),
                                label: Text(explore.apply),
                              ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        key: ValueKey('remove-${effect.id}'),
                        onPressed: onRemove,
                        tooltip: explore.removeFromLibrary,
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: WeColors.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
