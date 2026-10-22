import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/app_strings_scope.dart';
import '../../core/persistence/config_store.dart';
import '../../features/explore/explore.dart';
import '../../features/fans/fans.dart';
import '../../features/lighting/lighting.dart';
import '../../features/monitoring/monitoring.dart';
import '../navigation/app_route.dart';
import 'settings_page.dart';
import 'sidebar.dart';
import 'topbar.dart';

class Shell extends ConsumerStatefulWidget {
  const Shell({super.key});

  @override
  ConsumerState<Shell> createState() => _ShellState();
}

class _ShellState extends ConsumerState<Shell> {
  @override
  Widget build(BuildContext context) {
    // One notification per failed write: the provider emits a new event for
    // consecutive failures, and provider notifications reach the listener
    // without waiting for an unrelated frame or being dropped when a later
    // write succeeds first.
    ref.listen(configWriteFailuresProvider, (_, event) {
      if (event.value == null || !mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(context.strings.common.configWriteFailed)),
      );
    });
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
