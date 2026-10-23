import 'package:flutter/material.dart';

import '../../../../core/i18n/app_strings_scope.dart';
import '../../../../core/ui/we_card.dart';
import '../../domain/light_device.dart';
import '../../domain/lighting_config.dart';
import 'color_picker.dart';
import '../lighting_labels.dart';

/// Fixed-color panel for one device.
class FixedColorPanel extends StatelessWidget {
  const FixedColorPanel({
    super.key,
    required this.id,
    required this.config,
    required this.fanGroupNames,
    required this.onEdit,
  });

  final LightDeviceId id;
  final LightingConfig config;
  final List<String> fanGroupNames;
  final ValueChanged<LightingConfigEdit> onEdit;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return WeCard(
      flat: true,
      title: strings.lighting.fixedColorTitle(
        deviceLabel(strings, id, fanGroupNames),
      ),
      child: ColorPicker(
        color: config.device(id).fixedColor,
        onChanged: (c) => onEdit(
          (s) => s.withDevice(id, s.device(id).copyWith(fixedColor: c)),
        ),
      ),
    );
  }
}
