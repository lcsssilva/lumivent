import 'package:flutter/material.dart';

import '../../../../core/i18n/app_strings_scope.dart';
import '../../../../core/ui/we_colors.dart';
import '../../../../core/ui/we_sizes.dart';
import '../../../../core/ui/status_pill.dart';
import '../../application/fan_group_status.dart';
import '../../domain/fan_curve.dart';
import '../../domain/fan_group_config.dart';

part 'fan_group_header_state.dart';

class FanGroupHeader extends StatefulWidget {
  const FanGroupHeader({
    super.key,
    required this.group,
    required this.rpm,
    required this.status,
    required this.hubOk,
    required this.onName,
    required this.onSize,
  });

  final FanGroupConfig group;
  final double? rpm;
  final FanGroupStatus? status;
  final bool? hubOk;
  final ValueChanged<String> onName;
  final ValueChanged<FanSize> onSize;

  @override
  State<FanGroupHeader> createState() => _FanGroupHeaderState();
}
