import 'package:flutter/material.dart';

import '../../../core/i18n/app_strings_scope.dart';
import '../../../core/ui/theme.dart';

/// Shown when the installed-effect library has no effects.
class ExploreEmptyState extends StatelessWidget {
  const ExploreEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final explore = context.strings.explore;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_awesome_outlined,
            size: 42,
            color: WeColors.muted,
          ),
          const SizedBox(height: 12),
          Text(
            explore.noEffectsTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 430,
            child: Text(
              explore.noEffectsBody,
              textAlign: TextAlign.center,
              style: const TextStyle(color: WeColors.muted, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}
