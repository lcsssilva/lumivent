import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/app_strings.dart';

enum AppRoute {
  monitoring(Icons.monitor_heart_outlined),
  lighting(Icons.auto_awesome_outlined),
  fans(Icons.toys_outlined),
  explore(Icons.explore_outlined),
  settings(Icons.settings_outlined);

  const AppRoute(this.icon);
  final IconData icon;
}

extension AppRouteStrings on AppRoute {
  String label(AppStrings s) => switch (this) {
    AppRoute.monitoring => s.shell.monitoring,
    AppRoute.lighting => s.shell.lighting,
    AppRoute.fans => s.shell.fans,
    AppRoute.explore => s.shell.explore,
    AppRoute.settings => s.shell.settings,
  };

  String subtitle(AppStrings s) => switch (this) {
    AppRoute.monitoring => s.shell.monitoringSubtitle,
    AppRoute.lighting => s.shell.lightingSubtitle,
    AppRoute.fans => s.shell.fansSubtitle,
    AppRoute.explore => s.shell.exploreSubtitle,
    AppRoute.settings => s.shell.settingsSubtitle,
  };
}

class RouteNotifier extends Notifier<AppRoute> {
  @override
  AppRoute build() => AppRoute.monitoring;

  void go(AppRoute route) => state = route;
}

final routeProvider = NotifierProvider<RouteNotifier, AppRoute>(
  RouteNotifier.new,
);
