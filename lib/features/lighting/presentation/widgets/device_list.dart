// Top strip: one item per lighting device (status, switch, mode) in a
// horizontal carousel. Items have a fixed width and scroll sideways, with
// arrow buttons and a scrollbar; a mouse drag also scrolls.

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';

import '../../../../core/i18n/app_strings_scope.dart';
import '../../../../core/ui/we_card.dart';
import '../../domain/light_device.dart';
import '../../domain/config/lighting_config.dart';
import '../view_models/lighting_ui_state.dart';
import 'device_item.dart';

part 'device_list_state.dart';

class DeviceList extends StatefulWidget {
  const DeviceList({
    super.key,
    required this.ui,
    required this.onSelect,
    required this.onEdit,
  });

  /// Configuration, statuses, and selection of the lighting view.
  final LightingUiState ui;
  final ValueChanged<LightDeviceId> onSelect;
  final ValueChanged<LightingConfigEdit> onEdit;

  @override
  State<DeviceList> createState() => _DeviceListState();
}
