import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppRoute {
  monitoring(
    'Monitoramento',
    'Sensores da CPU, GPU, placa-mãe e SSDs',
    Icons.monitor_heart_outlined,
  ),
  lighting(
    'Iluminação',
    'Efeitos e cores de todos os dispositivos ARGB',
    Icons.auto_awesome_outlined,
  ),
  fans(
    'Fans',
    'Velocidade das fans AL V2 por curva ou preset',
    Icons.toys_outlined,
  ),
  explore('Explore', 'Biblioteca de efeitos', Icons.explore_outlined),
  settings(
    'Configurações',
    'Inicialização, preferências e diagnóstico',
    Icons.settings_outlined,
  );

  const AppRoute(this.label, this.subtitle, this.icon);
  final String label;
  final String subtitle;
  final IconData icon;
}

class RouteNotifier extends Notifier<AppRoute> {
  @override
  AppRoute build() => AppRoute.monitoring;

  void go(AppRoute route) => state = route;
}

final routeProvider = NotifierProvider<RouteNotifier, AppRoute>(
  RouteNotifier.new,
);
