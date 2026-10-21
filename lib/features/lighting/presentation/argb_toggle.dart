import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/theme.dart';
import '../application/lighting_controller.dart';

/// Global "ARGB" switch: off means all LEDs are off.
class ArgbToggle extends ConsumerWidget {
  const ArgbToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final off = ref.watch(lightingProvider.select((s) => s.argbOff));
    void set(bool v) => ref.read(lightingProvider.notifier).setArgbOff(v);
    return Tooltip(
      message: off ? 'Religar todos os ARGB' : 'Desligar todos os ARGB',
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
                off ? 'ARGB desligado' : 'ARGB',
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
