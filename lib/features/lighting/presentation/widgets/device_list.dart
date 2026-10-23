// Top strip: one item per lighting device (status, switch, mode) in a
// horizontal carousel. Items have a fixed width and scroll sideways, with
// arrow buttons and a scrollbar; a mouse drag also scrolls.

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';

import '../../../../core/i18n/app_strings_scope.dart';
import '../../../../core/ui/we_card.dart';
import '../../domain/light_device.dart';
import 'device_item.dart';

part 'device_list_state.dart';

class DeviceList extends StatefulWidget {
  const DeviceList({super.key, required this.selected, required this.onSelect});
  final LightDeviceId? selected;
  final ValueChanged<LightDeviceId> onSelect;

  @override
  State<DeviceList> createState() => _DeviceListState();
}
