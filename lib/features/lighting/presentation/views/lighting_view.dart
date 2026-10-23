import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/app_strings.dart';
import '../../../../core/i18n/app_strings_scope.dart';
import '../../../../core/ui/we_colors.dart';
import '../../../../core/ui/we_sizes.dart';
import '../../../../core/ui/we_card.dart';
import '../../domain/led_layout.dart';
import '../../domain/installed_effect.dart';
import '../../domain/lighting_config.dart';
import '../../domain/native_effects.dart';
import '../view_models/lighting_ui_state.dart';
import '../view_models/lighting_view_model.dart';
import '../widgets/device_list.dart';
import '../lighting_labels.dart';
import '../widgets/led_canvas.dart';
import '../widgets/lighting_mode_panel.dart';

part 'lighting_view_state.dart';

/// Lighting: devices in a horizontal strip on top, and a single card with the
/// canvas, the effect library, and the controls for the selected device or
/// global effect.
class LightingView extends ConsumerStatefulWidget {
  const LightingView({super.key});

  @override
  ConsumerState<LightingView> createState() => _LightingViewState();
}
