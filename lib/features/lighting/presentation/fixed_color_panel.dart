import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_strings_scope.dart';
import '../../../core/ui/we_card.dart';
import '../application/lighting_controller.dart';
import '../domain/light_device.dart';
import '../domain/lighting_config.dart';
import 'color_picker.dart';
import 'labels.dart';

/// Fixed-color panel for one device.
class FixedColorPanel extends ConsumerWidget {
  const FixedColorPanel({super.key, required this.id});
  final LightDeviceId id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(lightingProvider.select((c) => c.device(id)));
    final strings = context.strings;
    return WeCard(
      flat: true,
      title: strings.lighting.fixedColorTitle(
        deviceLabel(strings, id, ref.watch(fanGroupNamesProvider)),
      ),
      child: ColorPicker(
        color: cfg.fixedColor,
        onChanged: (c) => ref
            .read(lightingProvider.notifier)
            .update(
              (s) => s.withDevice(id, s.device(id).copyWith(fixedColor: c)),
            ),
      ),
    );
  }
}
