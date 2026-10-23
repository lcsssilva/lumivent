import 'package:flutter/material.dart';

import '../i18n/app_strings_scope.dart';
import 'status_dot.dart';
import 'status_pill.dart';
import 'we_colors.dart';
import 'we_sizes.dart';
import 'we_card.dart';

/// Placeholder page for an area planned for a future phase.
class PhasePlaceholder extends StatelessWidget {
  const PhasePlaceholder({super.key, required this.phase, required this.items});
  final int phase;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final s = context.strings.shell;
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.all(WeSizes.unit * 3),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: WeCard(
            title: s.underConstruction,
            trailing: StatusPill(
              label: s.phase(phase),
              color: WeColors.accentHover,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: StatusDot(WeColors.border, size: 6),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(color: WeColors.muted),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
