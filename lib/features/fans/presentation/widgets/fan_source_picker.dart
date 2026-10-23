import 'package:flutter/material.dart';

import '../../../../core/ui/we_colors.dart';
import '../../../../core/ui/we_sizes.dart';
import '../../domain/fan_group.dart';

/// Lists sources with the current value beside each name. CPU/GPU come first,
/// followed by the motherboard; unavailable board sources are hidden unless selected.
class FanSourcePicker extends StatelessWidget {
  const FanSourcePicker({
    super.key,
    required this.selected,
    required this.options,
    required this.onChanged,
  });

  final FanTempSource selected;
  final List<({FanTempSource source, String label, String value})> options;
  final ValueChanged<FanTempSource> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<FanTempSource>(
      value: selected,
      underline: const SizedBox.shrink(),
      borderRadius: BorderRadius.circular(WeSizes.radius),
      items: [
        for (final o in options)
          DropdownMenuItem(
            value: o.source,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(o.label),
                const SizedBox(width: WeSizes.unit * 1.5),
                Text(
                  o.value,
                  style: const TextStyle(color: WeColors.muted, fontSize: 12.5),
                ),
              ],
            ),
          ),
      ],
      onChanged: (s) {
        if (s != null) onChanged(s);
      },
    );
  }
}
