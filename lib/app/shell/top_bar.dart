import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/app_strings_scope.dart';
import '../../core/ui/theme.dart';
import '../../features/lighting/lighting.dart';
import '../../features/monitoring/monitoring.dart';
import '../navigation/app_route.dart';

class TopBar extends ConsumerWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = ref.watch(routeProvider);
    final s = context.strings.shell;
    return Container(
      height: WeSizes.topbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: WeSizes.unit * 3),
      decoration: const BoxDecoration(
        color: WeColors.bg,
        border: Border(bottom: BorderSide(color: WeColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  route.label(context.strings),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  route.subtitle(context.strings),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: WeColors.muted, fontSize: 12.5),
                ),
              ],
            ),
          ),
          const TopbarSensors(),
          const SizedBox(width: WeSizes.unit * 3),
          const ArgbToggle(),
          const SizedBox(width: WeSizes.unit),
          IconButton(
            tooltip: s.settingsTooltip,
            icon: const Icon(Icons.settings_outlined),
            color: route == AppRoute.settings
                ? WeColors.accentHover
                : WeColors.muted,
            onPressed: () =>
                ref.read(routeProvider.notifier).go(AppRoute.settings),
          ),
        ],
      ),
    );
  }
}
