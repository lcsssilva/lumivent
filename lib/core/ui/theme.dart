import 'package:flutter/material.dart';

import 'we_colors.dart';
import 'we_sizes.dart';

ThemeData buildTheme() {
  const scheme = ColorScheme.dark(
    primary: WeColors.accent,
    onPrimary: Colors.white,
    secondary: WeColors.accentHover,
    onSecondary: Colors.white,
    surface: WeColors.surface,
    onSurface: WeColors.text,
    onSurfaceVariant: WeColors.muted,
    surfaceContainerLowest: WeColors.bg,
    surfaceContainerLow: WeColors.surface,
    surfaceContainer: WeColors.surface,
    surfaceContainerHigh: WeColors.surface2,
    surfaceContainerHighest: WeColors.surface2,
    outline: WeColors.border,
    outlineVariant: WeColors.border,
    error: WeColors.danger,
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: WeColors.bg,
    dividerColor: WeColors.border,
    visualDensity: VisualDensity.standard,
  );
  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(WeSizes.radius),
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: WeColors.text,
      displayColor: WeColors.text,
    ),
    dividerTheme: const DividerThemeData(
      color: WeColors.border,
      thickness: 1,
      space: 1,
    ),
    cardTheme: CardThemeData(
      color: WeColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: shape.copyWith(side: const BorderSide(color: WeColors.border)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Colors.white : WeColors.muted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? WeColors.accent
            : WeColors.surface2,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? WeColors.accent
            : WeColors.border,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        side: const WidgetStatePropertyAll(BorderSide(color: WeColors.border)),
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? WeColors.accent.withValues(alpha: .18)
              : null,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? WeColors.accentHover
              : WeColors.text,
        ),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: WeColors.surface2,
        border: Border.all(color: WeColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(color: WeColors.text, fontSize: 12),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: WeColors.text,
        side: const BorderSide(color: WeColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );
}
