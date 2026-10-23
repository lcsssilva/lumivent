import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/i18n/app_strings_scope.dart';
import '../../../core/ui/status_pill.dart';
import '../../../core/ui/theme.dart';
import '../../lighting/lighting.dart';

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
                _Thumb(effect: effect, bytes: thumbnail),
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
                            child: _Tag(text: tag),
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

class _Thumb extends StatelessWidget {
  const _Thumb({required this.effect, required this.bytes});
  final InstalledEffect effect;
  final Future<Uint8List?>? bytes;

  @override
  Widget build(BuildContext context) {
    final future = bytes;
    if (future != null) {
      return FutureBuilder<Uint8List?>(
        future: future,
        builder: (context, snapshot) {
          final data = snapshot.data;
          if (data != null) {
            return Image.memory(
              data,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              // A frame is 320×200: keep it crisp.
              filterQuality: FilterQuality.medium,
            );
          }
          return _placeholder();
        },
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    final hash = effect.id.hashCode.abs();
    final hue = (hash % 360).toDouble();
    final start = HSVColor.fromAHSV(1, hue, .55, .38).toColor();
    final end = HSVColor.fromAHSV(1, (hue + 55) % 360, .65, .18).toColor();
    final initial = effect.title.trim().isEmpty
        ? '?'
        : effect.title.trim().characters.first.toUpperCase();
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [end, start],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: .82),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: WeColors.surface2,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: WeColors.border),
    ),
    child: Text(
      text,
      style: const TextStyle(color: WeColors.muted, fontSize: 10.5),
    ),
  );
}
