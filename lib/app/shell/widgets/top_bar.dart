import 'package:flutter/material.dart';

import '../../../core/i18n/app_strings_scope.dart';
import '../../../core/ui/we_colors.dart';
import '../../../core/ui/we_sizes.dart';
import '../../../features/lighting/lighting.dart';
import '../../../features/monitoring/monitoring.dart';
import '../../../features/preferences/preferences.dart';
import '../../navigation/app_route.dart';

class TopBar extends StatelessWidget {
  const TopBar({
    super.key,
    required this.route,
    required this.latestSensors,
    required this.temperatureUnit,
    required this.argbOff,
    required this.onRoute,
    required this.onArgbOff,
  });

  final AppRoute route;

  /// Latest sensor reading, `null` before the first one.
  final SensorSample? latestSensors;
  final TemperatureUnit temperatureUnit;

  /// Whether all ARGB is off.
  final bool argbOff;
  final ValueChanged<AppRoute> onRoute;

  /// Turns all ARGB off (`true`) or back on (`false`).
  final ValueChanged<bool> onArgbOff;

  @override
  Widget build(BuildContext context) {
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
          TopbarSensors(latest: latestSensors, unit: temperatureUnit),
          const SizedBox(width: WeSizes.unit * 3),
          ArgbToggle(off: argbOff, onChanged: onArgbOff),
          const SizedBox(width: WeSizes.unit),
          IconButton(
            tooltip: s.settingsTooltip,
            icon: const Icon(Icons.settings_outlined),
            color: route == AppRoute.settings
                ? WeColors.accentHover
                : WeColors.muted,
            onPressed: () => onRoute(AppRoute.settings),
          ),
        ],
      ),
    );
  }
}
