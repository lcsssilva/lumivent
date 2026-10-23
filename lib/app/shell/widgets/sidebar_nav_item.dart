import 'package:flutter/material.dart';

import '../../../core/i18n/app_strings_scope.dart';
import '../../../core/ui/we_colors.dart';
import '../../navigation/app_route.dart';

class SidebarNavItem extends StatelessWidget {
  const SidebarNavItem({
    super.key,
    required this.route,
    required this.selected,
    required this.onTap,
  });
  final AppRoute route;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? WeColors.text : WeColors.muted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? WeColors.surface2 : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          hoverColor: WeColors.surface2,
          onTap: onTap,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: selected
                ? const BoxDecoration(
                    border: Border(
                      left: BorderSide(color: WeColors.accent, width: 3),
                    ),
                  )
                : null,
            child: Row(
              children: [
                Icon(
                  route.icon,
                  size: 20,
                  color: selected ? WeColors.accentHover : fg,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    route.label(context.strings),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: fg,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
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
