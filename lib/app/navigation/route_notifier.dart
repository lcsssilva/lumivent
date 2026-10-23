import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_route.dart';

class RouteNotifier extends Notifier<AppRoute> {
  @override
  AppRoute build() => AppRoute.monitoring;

  void go(AppRoute route) => state = route;
}

final routeProvider = NotifierProvider<RouteNotifier, AppRoute>(
  RouteNotifier.new,
);
