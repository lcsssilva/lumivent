import 'package:flutter/material.dart';

import '../../../core/ui/we_colors.dart';
import '../../../core/ui/we_sizes.dart';
import '../../../features/devices/devices.dart';
import '../../navigation/app_route.dart';
import 'sidebar_brand.dart';
import 'sidebar_nav_item.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({
    super.key,
    required this.route,
    required this.devices,
    required this.onRoute,
  });

  final AppRoute route;

  /// Last device detection, `null` while the first scan runs.
  final DeviceSnapshot? devices;
  final ValueChanged<AppRoute> onRoute;

  static const _main = [
    AppRoute.monitoring,
    AppRoute.lighting,
    AppRoute.fans,
    AppRoute.explore,
  ];

  @override
  Widget build(BuildContext context) {
    void go(AppRoute r) => onRoute(r);

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
          DeviceSummary(snapshot: devices),
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
