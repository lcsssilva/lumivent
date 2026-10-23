import 'package:flutter/material.dart';

import '../../../../core/i18n/app_strings_scope.dart';
import '../../../../core/ui/we_colors.dart';
import '../../../../core/ui/we_sizes.dart';
import '../../domain/ssd_info.dart';
import '../ssd_error_text.dart';

class SsdSmartBanner extends StatelessWidget {
  const SsdSmartBanner(this.ssds, {super.key});
  final List<SsdInfo> ssds;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final reasons = {
      for (final ssd in ssds)
        if (ssd.smartError case final error?) ssdErrorText(error, strings),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: WeSizes.unit * 1.5),
      padding: const EdgeInsets.all(WeSizes.unit * 1.5),
      decoration: BoxDecoration(
        color: WeColors.warn.withValues(alpha: .1),
        border: Border.all(color: WeColors.warn.withValues(alpha: .4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: WeColors.warn, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(strings.monitoring.smartUnavailable),
                const SizedBox(height: 2),
                Text(
                  reasons.join(' · '),
                  style: const TextStyle(color: WeColors.muted, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
