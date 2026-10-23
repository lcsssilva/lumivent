import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/app_strings_scope.dart';
import '../../../../core/ui/async_action.dart';
import '../../../../core/ui/we_colors.dart';
import '../../../../core/ui/we_card.dart';
import '../../../../core/ui/setting_row.dart';
import '../../domain/autostart/autostart_exception.dart';
import '../../domain/autostart/autostart_state.dart';

part 'startup_card_state.dart';

class StartupCard extends StatefulWidget {
  const StartupCard({
    super.key,
    required this.autostart,
    required this.location,
    required this.onChanged,
  });

  /// Autostart state as the service reports it.
  final AsyncValue<AutostartState> autostart;

  /// Path of the systemd unit, shown to the user.
  final String location;

  /// Turns autostart on or off; errors end up in [autostart].
  final Future<void> Function(bool enabled) onChanged;

  @override
  State<StartupCard> createState() => _StartupCardState();
}
