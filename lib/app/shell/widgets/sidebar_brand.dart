import 'package:flutter/material.dart';

import '../../../core/ui/we_colors.dart';
import '../../../core/ui/we_sizes.dart';

class SidebarBrand extends StatelessWidget {
  const SidebarBrand({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: WeSizes.topbarHeight,
    child: Row(
      children: [
        const SizedBox(width: 6),
        Transform.rotate(
          angle: .785398,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [WeColors.accentHover, Color(0xFF5B3CFF)],
              ),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        const SizedBox(width: 14),
        const Text(
          'Lumivent',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}
