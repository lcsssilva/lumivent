import 'package:flutter/material.dart';

import '../../../../core/i18n/app_strings_scope.dart';
import '../../../../core/ui/we_colors.dart';
import '../../../../core/ui/we_sizes.dart';
import '../../domain/fan_group_config.dart';

class FanGroupTile extends StatelessWidget {
  const FanGroupTile({
    super.key,
    required this.config,
    required this.rpm,
    required this.hasFan,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final FanGroupConfig config;
  final double? rpm;
  final bool hasFan;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final shape = BorderRadius.circular(WeSizes.radius);
    return Opacity(
      opacity: hasFan || selected ? 1 : .5,
      child: Material(
        color: selected
            ? WeColors.accent.withValues(alpha: .12)
            : WeColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: shape,
          side: BorderSide(color: selected ? WeColors.accent : WeColors.border),
        ),
        child: InkWell(
          key: ValueKey('group-${config.group}'),
          borderRadius: shape,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(WeSizes.unit * 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      '${config.size.diameterMm} mm',
                      style: const TextStyle(
                        color: WeColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  hasFan
                      ? '${strings.grouped((rpm ?? 0).round())} RPM'
                      : strings.fans.noFan,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: hasFan ? WeColors.text : WeColors.muted,
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
