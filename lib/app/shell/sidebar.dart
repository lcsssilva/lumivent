import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/app_strings_scope.dart';
import '../../core/ui/theme.dart';
import '../../features/devices/devices.dart';
import '../navigation/app_route.dart';

class Sidebar extends ConsumerWidget {
  const Sidebar({super.key});

  static const _main = [
    AppRoute.monitoring,
    AppRoute.lighting,
    AppRoute.fans,
    AppRoute.explore,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = ref.watch(routeProvider);
    void go(AppRoute r) => ref.read(routeProvider.notifier).go(r);

    return Container(
      width: WeSizes.sidebarWidth,
      color: WeColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Brand(),
          for (final r in _main)
            _NavItem(route: r, selected: r == route, onTap: () => go(r)),
          const Spacer(),
          const DeviceSummary(),
          const Divider(height: 24),
          _NavItem(
            route: AppRoute.settings,
            selected: route == AppRoute.settings,
            onTap: () => go(AppRoute.settings),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: WeSizes.topbarHeight,
    child: Row(
      children: [
        const SizedBox(width: 6),
        Transform.rotate(
          angle: .785398,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [WeColors.accentHover, Color(0xFF5B3CFF)],
              ),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        const SizedBox(width: 14),
        const Text(
          'Lumivent',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _NavItem extends StatelessWidget {
  const _NavItem({
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
