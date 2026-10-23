import 'package:flutter/material.dart';

import '../../../../core/i18n/app_strings_scope.dart';
import '../../../../core/ui/we_colors.dart';

/// Global "ARGB" switch: off means all LEDs are off.
class ArgbToggle extends StatelessWidget {
  const ArgbToggle({super.key, required this.off, required this.onChanged});

  /// Whether all ARGB is off.
  final bool off;

  /// Turns all ARGB off (`true`) or back on (`false`).
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.strings.lighting;
    void set(bool v) => onChanged(v);
    return Tooltip(
      message: off ? l.turnOnAllArgb : l.turnOffAllArgb,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => set(!off),
        child: Container(
          padding: const EdgeInsets.only(left: 14, right: 4),
          height: 36,
          decoration: BoxDecoration(
            color: WeColors.surface,
            border: Border.all(color: WeColors.border),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                off ? Icons.lightbulb_outline : Icons.lightbulb,
                size: 16,
                color: off ? WeColors.muted : WeColors.accentHover,
              ),
              const SizedBox(width: 8),
              Text(
                off ? l.argbOff : l.argb,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: off ? WeColors.muted : WeColors.text,
                ),
              ),
              const SizedBox(width: 4),
              Transform.scale(
                scale: .8,
                child: Switch(value: !off, onChanged: (on) => set(!on)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
