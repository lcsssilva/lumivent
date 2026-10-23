// Center column: 320×200 canvas with the effect preview behind and each
// canvas/fixed device drawn with its real LEDs. The GPU has no LEDs: its
// rectangle is drawn as the area whose average color it shows. Drag moves, the
// corner handle resizes.
//
// Devices in Hardware mode (or turned off) are not drawn: their LEDs are
// driven by the device itself, so there is nothing meaningful to preview.

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';

import '../../domain/led_layout.dart';
import '../../domain/canvas_rect.dart';
import '../../domain/light_device.dart';
import '../../domain/effect_frame.dart';
import '../../domain/lighting_config.dart';
import '../on_canvas.dart';
import 'led_canvas_painter.dart';

part 'led_canvas_state.dart';

const _handlePx = 14.0;
const _minW = 10.0, _minH = 6.0;

/// New size after a resize drag. [room] is the space left to the canvas edge;
/// when it is below [min] the result is [room] (never throws).
double resizeExtent(double size, double delta, double min, double room) =>
    (size + delta).clamp(math.min(min, room), room).toDouble();

class LedCanvas extends StatefulWidget {
  const LedCanvas({
    super.key,
    required this.config,
    required this.time,
    required this.selected,
    required this.onSelect,
    required this.onPlace,
    this.frame,
  });
  final LightingConfig config;

  /// Effect clock in seconds, updated by the page ticker (~30 fps).
  final ValueListenable<double> time;
  final LightDeviceId? selected;
  final ValueChanged<LightDeviceId?> onSelect;
  final void Function(LightDeviceId id, CanvasRect rect) onPlace;

  /// Last frame of the installed HTML effect, when one is running.
  final ValueListenable<EffectFrame?>? frame;

  @override
  State<LedCanvas> createState() => _LedCanvasState();
}
