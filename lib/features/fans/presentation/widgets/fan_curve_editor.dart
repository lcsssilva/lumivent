import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/i18n/app_strings.dart';
import '../../../../core/i18n/app_strings_scope.dart';
import '../../../../core/ui/we_colors.dart';
import '../../domain/fan_curve.dart';
import '../../domain/fan_point.dart';
import '../../domain/fan_presets.dart';
import '../../domain/fan_group_config.dart';
import 'fan_curve_live.dart';

part 'fan_curve_editor_state.dart';
part 'fan_curve_plot.dart';
part 'fan_curve_painter.dart';

/// Curve editor: X = 0–100 °C, Y = 0–100% (secondary axis in RPM).
///
/// Dragging moves a point (X stays between its neighbors), double-clicking empty
/// space adds a point, and right-clicking a point removes it. Fixed mode only
/// allows vertical dragging of its single point.
class FanCurveEditor extends StatefulWidget {
  const FanCurveEditor({
    super.key,
    required this.group,
    required this.live,
    required this.onChanged,
    required this.onCommit,
    this.height = 320,
  });

  final FanGroupConfig group;
  final FanCurveLive live;

  /// Called for every point change (while dragging, without saving).
  final ValueChanged<FanGroupConfig> onChanged;

  /// End of an edit: save now.
  final VoidCallback onCommit;
  final double height;

  @override
  State<FanCurveEditor> createState() => _FanCurveEditorState();
}
