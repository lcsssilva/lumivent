import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/we_colors.dart';
import '../../../core/ui/we_sizes.dart';
import '../../../features/devices/devices.dart';
import '../../navigation/app_route.dart';
import '../../navigation/route_notifier.dart';
import 'sidebar_brand.dart';
import 'sidebar_nav_item.dart';

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
          const SidebarBrand(),
          for (final r in _main)
            SidebarNavItem(route: r, selected: r == route, onTap: () => go(r)),
          const Spacer(),
          const DeviceSummary(),
          const Divider(height: 24),
          SidebarNavItem(
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
