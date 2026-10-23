import 'package:flutter/material.dart';

import '../../../core/ui/we_colors.dart';
import '../domain/ssd.dart';

Color ssdHealthColor(SsdHealth health) => switch (health) {
  SsdHealth.good => WeColors.ok,
  SsdHealth.caution => WeColors.warn,
  SsdHealth.bad => WeColors.danger,
};
