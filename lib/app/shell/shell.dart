import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/explore/explore.dart';
import '../../features/fans/fans.dart';
import '../../features/lighting/lighting.dart';
import '../../features/monitoring/monitoring.dart';
import '../navigation/app_route.dart';
import 'settings_page.dart';
import 'sidebar.dart';
import 'topbar.dart';

class Shell extends ConsumerWidget {
  const Shell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = ref.watch(routeProvider);
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Sidebar(),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const TopBar(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: KeyedSubtree(
                      key: ValueKey(route),
                      child: _page(route),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _page(AppRoute route) => switch (route) {
    AppRoute.monitoring => const MonitoringPage(),
    AppRoute.lighting => const LightingPage(),
    AppRoute.fans => const FansPage(),
    AppRoute.explore => const ExplorePage(),
    AppRoute.settings => const SettingsPage(),
  };
}
